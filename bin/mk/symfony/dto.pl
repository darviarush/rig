#!/usr/bin/perl

# Создаёт Response контроллера и его DTO по описанию в формате OpenApi по структуре из json

use common::sense;
use open qw/:std :utf8/;

use Aion::Fs;
use Aion::Format::Yaml;
use Aion::Format::Json;

my ($controller, $txt) = @ARGV;

$txt = cat $txt;
my $s;
$s = from_json $txt if $txt =~ /^\s*{/;
$s = from_yaml $txt if !$s;
die "Формат не распознан!" if !$s;

my $response = $controller =~ s/Controller\.php$/Response\.php/r;
my $namespace = (($controller =~ s!/[^/]*$!!r) =~ s!/!\\!gr) =~ s!^src!App!r;

my ($class) = $controller =~ m/([^\/]*)Controller\.php$/;

open my $f, ">", mkpath $controller or die "$controller: $!";
print $f << "END";
<?php

declare(strict_types=1);

namespace $namespace;

use Nelmio\ApiDocBundle\Attribute\Model;
use OpenApi\Attributes as OA;


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
END

# Рекурсивно обходит структуру
sub mkDto (@);
sub mkDto (@) {
	my ($s, $path, $is_array) = @_;
	
	my $name = $path->[$#$path];
	my $Name = lcfirst $name;
	
	if(ref $s eq "HASH") {
		my $c = @$path == 1? "${class}Response": "$class${Name}DTO";
		my $p = @$path == 1? $response: do { ($controller =~ s!/[^/]*$!!r) . "/DTO/$class${Name}DTO.php" };
		my $properties = join "", map { mkDto $s->{$_}, [@$path, $_] } sort keys %$s;
		my $required = join ", ", map "'$_'", sort keys %$s;
		lay mkpath $p, << "END";
<?php

declare(strict_types=1);

namespace App\Controller\Api\TechConnect\Show\DTO;

use Nelmio\ApiDocBundle\Annotation\Model;
use OpenApi\Attributes as OA;

#[OA\Schema(
    title: '',
    description: '',
    required: [$required],
)]
final class $class${Name}DTO
{
    public function __construct(
$properties
	)
}
END
		
	}
	elsif(ref $s eq "ARRAY") {
		mkDto $s->[0], [@$path, $_], 1;
	}
	elsif($s =~ /^\d+$/) {
        << "END";
        #[OA\\Property(
            description: '',
            type: 'integer',
            example: $s,
            nullable: false,
        )]
        public int \$$name,
END
	}
	elsif($s =~ /^\d+\.\d+$/) {
        << "END";
        #[OA\\Property(
            description: '',
            type: 'float',
            example: $s,
            nullable: false,
        )]
        public float \$$name,
END
	}
	elsif($s =~ /^\d+-\d+-\d+$/) {
        << "END";
		#[OA\\Property(
            description: '',
            type: 'string',
            format: 'date',
            example: '$s',
            nullable: false,
        )]
        public string \$$name,
END
	}
	elsif($s =~ /^\d+-\d+-\d+/) {
		<< "END";
		#[OA\\Property(
            description: '',
            type: 'string',
            format: 'datetime',
            example: '$s',
            nullable: false,
        )]
        public string \$$name,
END
	}
	else {
        << "END";
        #[OA\\Property(
            description: '',
            type: 'string',
            example: '$s',
            nullable: false,
        )]
        public string \$$name,
END
	}
}


