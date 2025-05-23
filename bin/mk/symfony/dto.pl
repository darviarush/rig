#!/usr/bin/perl

# Создаёт Response контроллера и его DTO по описанию в формате OpenApi по структуре из json

use common::sense;
use open qw/:std :utf8/;

use Aion::Fs;
use Aion::Format::Yaml;
use Aion::Format::Json;

my ($controller, $txt) = @ARGV;
$txt = $controller, $controller = $txt =~ s/(\.[^\/]*)?$/.php/r if !defined $txt;

$txt = cat $txt;
my $s;
$s = from_json $txt if $txt =~ /^\s*{/;
$s = from_yaml $txt if !$s;
die "Формат не распознан!" if !$s;

my $response = $controller =~ s/Controller\.php$/Response\.php/r;
my $namespace = (($controller =~ s!/[^/]*$!!r) =~ s!/!\\!gr) =~ s!^src!App!r;

my ($class) = $controller =~ m/([^\/]*)Controller\.php$/;

open my $f, ">", mkpath $controller or die "$controller: $!";
print $f (<< "END");
<?php

declare(strict_types=1);

namespace $namespace;

use App\\Storage\\User\\Permission\\Enum\\PermissionEnum;
use OpenApi\\Attributes as OA;
use Nelmio\\ApiDocBundle\\Attribute\\Model;
use Symfony\\Component\\HttpKernel\\Attribute\\AsController;
use Symfony\\Component\\Routing\\Annotation\\Route;
use Symfony\\Component\\Security\\Http\\Attribute\\IsGranted;

#[Route(path: '', name: '', methods: ['GET'])]
#[AsController]
#[IsGranted(PermissionEnum::XXX->value)]
#[OA\\Get(
    path: '',
    summary: '',
    tags: [''],
    parameters: [
        new OA\\Parameter(
            name: 'id',
            description: '',
            in: 'path',
            required: true,
            schema: new OA\\Schema(type: 'string', format: 'uuid', example: '1efb0164-b719-680c-89da-bffcd378727d'),
        ),
    ],
    responses: [
        new OA\\Response(
            response: 200,
            description: '',
            content: new OA\\JsonContent(properties: [
                new OA\\Property(
                    property: 'success',
                    type: 'boolean',
                    example: true,
                ),
                new OA\\Property(
                    property: 'data',
                    type: 'object',
                    allOf: [new OA\\Schema(
                        ref: new Model(type: ${class}Response::class),
                    )],
                ),
            ]),
        ),
    ],
)]

final readonly class ${class}Controller
{
    public function __construct(
    ) {
    }

    public function __invoke(
    ): ${class}Response {
		return new ${class}Response(
END

# Рекурсивно обходит структуру
sub mkDto (@);
mkDto $s, ["Response"];

my %P;

sub mkDto (@) {
    my ($s, $path, $is_array) = @_;
    
    my $name = $path->[$#$path];
    my $Name = ucfirst $name;
    my $prop; my $type;
    
    if(ref $s eq "HASH") {
        my $c = @$path == 1? "${class}Response": "$class${Name}DTO";
        my $namespaceDTO = @$path == 1? $namespace: "${namespace}\\DTO";
        my $p = @$path == 1? $response: do { ($controller =~ s!/[^/]*$!!r) . "/DTO/$class${Name}DTO.php" };
        my $properties = join "", map { mkDto $s->{$_}, [@$path, $_] } sort keys %$s;
        my $required = join ", ", map "'$_'", sort keys %$s;
        die "Файл $p уже есть!" if exists $P{$p};
        $P{$p} = 1;
		
		my $title = enru($c);
		
        lay mkpath $p, << "END";
<?php

declare(strict_types=1);

namespace $namespaceDTO;

use Nelmio\\ApiDocBundle\\Annotation\\Model;
use OpenApi\\Attributes as OA;

#[OA\\Schema(
    title: '$title',
    description: '$title',
    required: [$required],
)]
final class $c
{
    public function __construct(
$properties    ) {
    }
}
END
        $type = $c;
        $prop = << "END";
            ref: new Model(type: ${c}::class),
END
    }
    elsif(ref $s eq "ARRAY") {
        return mkDto $s->[0], $path, 1;
    }
    else {
        my $oatype; my $ex; my $fmt;
        if(UNIVERSAL::isa($s, 'JSON::PP::Boolean')) {
            $oatype = 'boolean';
            $type = 'bool';
            $ex = 'true';
        }
        elsif($s =~ /^\d+$/) {
            $oatype = 'integer';
            $type = 'int';
            $ex = $s;
        }
        elsif($s =~ /^\d+\.\d+$/) {
            $oatype = $type = 'float';
            $ex = $s;
        }
        elsif($s =~ /^\d+.\d+.\d+$/) {
            $oatype = 'string';
            $type = '\DateTimeImmutable';
            $ex = "'$s'";
            $fmt = "format: date";
        }
        elsif($s =~ /^\d+.\d+.\d+/) {
            $oatype = 'string';
            $type = '\DateTimeImmutable';
            $ex = "'$s'";
            $fmt = "format: datetime";
        }
        else {
            $oatype = $type = 'string';
            $ex = "'$s'";
        }
    
		my $desc = enru($name);
	
        $prop = << "END";
            description: '$desc',
            type: '$oatype',
            example: $ex,
            nullable: false,
END
    }

	print $f "    " x (3+@$path), "$name: \$$name,\n";

    if ($is_array) {
        $prop =~ s/^/    /mg;
        << "END";
        #[OA\\Property(
            type: 'array',
            items: new OA\\Items(
$prop            ),
        )]
        public array \$$name,
END
    } else {
        << "END";
        #[OA\\Property(
$prop        )]
        public $type \$$name,
END
    }
}


print $f +<< "END";
        );
    }
}
END

sub enru {
	my ($name) = @_;
	my $desc_path = "/tmp/.rig-symfony-dto/$name";
	-e $desc_path? cat $desc_path: do {
		my $en = lcfirst($name) =~ s/DTO|[A-Z]/" ".(length($&) == 1? lc($&): $&)/ger;
		print "$en -> ";
		my $i = "/tmp/i";
		my $o = "/tmp/o";
		lay $i, $en;
		my $com = "trans en:ru -b -i $i -o $o -no-rlwrap -no-init";
		system($com) == 0 or die "$com: $?";
		my $desc = ucfirst cat $o;
		$desc =~ s/\s*$//;
		lay mkpath $desc_path, $desc;
		print $desc, "\n";
		$desc
	};
}
