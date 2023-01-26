<?php

declare(strict_types=1);

namespace Restoclub\{{Name}}Bundle\Entity;

use DateTime;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\ORM\Mapping as ORM;
use JMS\Serializer\Annotation as JMS;
use Restoclub\CatalogueBundle\Entity\Place;
use Restoclub\CityBundle\Entity\City;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * @ORM\Table(name="{{name}}.{{name}}")
 * @ORM\Entity()
 * @ORM\HasLifecycleCallbacks
 * @JMS\ExclusionPolicy("all")
 */
class {{Name}}
{
    /**
     * @ORM\Column(name="id", type="integer")
     * @ORM\Id
     * @ORM\GeneratedValue(strategy="AUTO")
     * @JMS\Expose()
     */
    private int $id;

    /**
     * @ORM\ManyToOne(targetEntity="Restoclub\CatalogueBundle\Entity\Place")
     * @ORM\JoinColumn(name="place_id")
     */
    public ?Place $place = null;

    /**
     * @ORM\Column(type="text", nullable=false)
     */
    public string $client;


    public function getId()
    {
        return $this->id;
    }

    public function __toString(): string
    {
        return "{{Name}}-" . $this->id;
    }
}
