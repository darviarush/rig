#!/usr/bin/perl

use common::sense;
use open qw/:std utf8/;

use Aion::Fs;
use Aion::Format::Yaml;
sub to_snake_case($);

my %DOCTRINE_TYPE = (
	date => "DATE_IMMUTABLE",
	datetime => "DATETIME_IMMUTABLE",
	integer => 'INTEGER',
	string => 'STRING',
);

my %PHP_TYPE = (
	date => '\DateTimeImmutable',
	datetime => '\DateTimeImmutable',
	integer => 'int',
	string => 'string',
);

my ($path, $yml) = @ARGV;

my ($Name) = $path =~ m!/(\w+)\.php$! or die "Нет имени файла $path";
my $name = to_snake_case($Name) . "s";
my $namespace = (($path =~ s/^src/App/r) =~ y!/!\\!r) =~ s!\\[^\\]*$!!r;
my ($pgns) = $path =~ m!^src/Storage/(\w+)/!;
$pgns = to_snake_case($pgns) . "s";


$yml = from_yaml cat $yml;
$yml = $yml->{"AppBundle\\Entity\\$Name"};
my $comment = $yml->{options}{comment};
my $fields_yml = $yml->{fields};
my $m2o_yml = $yml->{manyToOne};

my $fields;
if($fields_yml) {
	$fields = join "", map {
		my $v = $fields_yml->{$_};
		my $type = $v->{type};
		my $nullable = $v->{nullable};
		my $comment = $v->{options}{comment};
		
		my $null = $nullable? 'true': 'false';
		my $snull = $nullable? '?': '';
		my $znull = $nullable? ' = null': '';
		
		my $dtype = $DOCTRINE_TYPE{$type} // die "doctrine $type?";
		my $stype = $PHP_TYPE{$type} // die "php $type?";

		<< "END"
    #[ORM\\Column(type: Types::$dtype, nullable: $null, options: [
        'comment' => '$comment',
    ])]
    private $snull$stype \$$_$znull;

END
	} keys %$fields_yml;
}

my $m2o;
if($m2o_yml) {
	$m2o = join "", map {
		my $v = $m2o_yml->{$_};
		my $ref = $v->{targetEntity};
		my $inversedBy = $v->{inversedBy}; $inversedBy = $inversedBy? "'$inversedBy'": 'null';
		my $nullable = $v->{joinColumn}{nullable};
		my $comment = $v->{joinColumn}{options}{comment};
		
		my $null = $nullable? 'true': 'false';
		my $snull = $nullable? '?': '';
		
		<< "END"
    #[ORM\\ManyToOne(targetEntity: ${ref}::class, inversedBy: $inversedBy)]
    #[ORM\\JoinColumn(nullable: $null, options: [
        'comment' => '$comment',
    ])]
    private $snull$ref \$$_;

END
	} keys %$m2o_yml;
}


lay mkpath $path, << "END";
<?php

declare(strict_types=1);

namespace $namespace;

use App\\Enum\\Trait\\EntityIdentityUuidTrait;
use App\\Enum\\Trait\\EntityTimestampableTrait;
use Doctrine\\DBAL\\Types\\Types;
use Doctrine\\ORM\\Mapping as ORM;

#[ORM\\Table(name: '$pgns.$name', options: [
	'comment' => '$comment',
])]
#[ORM\\Entity(repositoryClass: ${Name}Repository::class)]
class $Name
{
    use EntityIdentityUuidTrait;
    use EntityTimestampableTrait;
	
$fields
$m2o
}
END

my $repo = $path =~ s/\.php$/Repository$&/r;
lay $repo, << "END";
<?php

declare(strict_types=1);

namespace $namespace;

use Doctrine\\Bundle\\DoctrineBundle\\Repository\\ServiceEntityRepository;
use Doctrine\\Persistence\\ManagerRegistry;

/**
 * \@method $Name|null find(\$id, \$lockMode = null, \$lockVersion = null)
 * \@method $Name|null findOneBy(array \$criteria, array \$orderBy = null)
 * \@method ${Name}[]    findAll()
 * \@method ${Name}[]    findBy(array \$criteria, array \$orderBy = null, \$limit = null, \$offset = null)
 *
 * \@extends ServiceEntityRepository<$Name>
 */
final class ${Name}Repository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry \$registry)
    {
        parent::__construct(\$registry, ${Name}::class);
    }
}
END



sub to_snake_case($) {
	my ($x) = @_;
	lcfirst($x) =~ s/[A-Z]/_${\lc $&}/gr
}


