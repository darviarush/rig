use Aion::Fs qw/mkpath /;


if($ARGV[0] eq "s") {

my ($type, $name, $f) = @_;

$_ = << 'END';
<?php

namespace App\Storage\{{name}};

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity()]
class Resource
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private int $id;

    #[ORM\Column(length: 255)]
    private string $name;

    #[ORM\Column]
    private bool $isTechConnect;

    public function getId(): int
    {
        return $this->id;
    }
}
END



}