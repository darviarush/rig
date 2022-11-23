<?php

declare(strict_types=1);

namespace Restoclub\AnalyticsBundle\Entity;

use DateTime;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\ORM\Mapping as ORM;
use JMS\Serializer\Annotation as JMS;
use Restoclub\CatalogueBundle\Entity\Place;
use Restoclub\CityBundle\Entity\City;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * @ORM\Table(name="analytics.guests_and_restorators")
 * @ORM\Entity()
 * @ORM\HasLifecycleCallbacks
 * @JMS\ExclusionPolicy("all")
 */
class GuestsAndRestorators
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
     * @ORM\JoinColumn(name="city_id")
     */
    public ?Place $place = null;

    /**
     * @ORM\Column(type="text", nullable=false)
     */
    public string $client;

    /**
     * @ORM\ManyToOne(targetEntity="Restoclub\CityBundle\Entity\City")
     * @ORM\JoinColumn(name="city_id")
     */
    public ?City $city = null;

    /**
     * @ORM\Column(type="text", nullable=false)
     */
    public string $address;

    /**
     * @ORM\Column(type="text", nullable=false)
     */
    public string $service;

    /**
     * @ORM\Column(type="datetime", nullable=true)
     */
    public ?DateTime $payedBeginAt;

    /**
     * @ORM\Column(type="datetime", nullable=true)
     */
    public ?DateTime $payedEndAt;

    /**
     * @ORM\Column(type="integer", nullable=true)
     */
    public ?int $period;

    /**
     * @ORM\Column(type="integer", nullable=true)
     */
    public ?int $costOnMonth;

    /**
     * @ORM\Column(type="integer", nullable=true)
     */
    public ?int $guestsGoToCart;

    /**
     * @ORM\Column(type="integer", nullable=true)
     */
    public ?int $lids;

    /**
     * @ORM\Column(type="decimal", precision=10, scale=2, nullable=true)
     */
    public ?float $costGoto;

    /**
     * @ORM\Column(type="money", nullable=true)
     */
    public ?string $costLid;

    /**
     * @ORM\Column(type="text", nullable=true)
     */
    public ?string $traffic;

    /**
     * @ORM\Column(type="integer", nullable=true)
     */
    public ?int $answers;

    /**
     * @ORM\Column(type="text", nullable=true)
     */
    public ?string $entersInCabinet;

    public function getId()
    {
        return $this->id;
    }

    public function __toString(): string
    {
        return "client-" . $this->id;
    }
}
