<?php

namespace Restoclub\{{Name}}Bundle\Admin;

use Restoclub\CoreBundle\Admin\AbstractAdmin;
use Sonata\AdminBundle\Datagrid\ListMapper;
use Sonata\AdminBundle\Form\FormMapper;
use Sonata\AdminBundle\Route\RouteCollection;

class {{Name}}Admin extends AbstractAdmin
{
    protected $baseRouteName    = '{{name}}-route';
    protected $baseRoutePattern = '{{name}}/route';

    public function getExportFormats(): array
    {
        return ['xls', 'csv'];
    }

    public function getExportFields(): array
    {
        return ['id'];
    }

    protected function configureRoutes(RouteCollection $collection): void
    {
        $collection->clearExcept(['list']);

        $collection->add('updateReport', 'update-report');
    }

    protected function configureListFields(ListMapper $list): void
    {
        $list
            ->add('place.id', null, [
                'label' => '#',
            ])
            ->add('client', null, [
                'label' => 'клиент',
            ])
            ->add('city.name', null, [
                'label' => 'город',
            ])
            ->add('address', null, [
                'label' => 'адрес',
            ])
            ->add('service', null, [
                'label' => 'тариф',
            ])
            ->add('payedBeginAt', 'datetime', [
                'format' => 'd M y',
                'locale' => 'ru',
                'label' => 'платили С',
            ])
            ->add('payedEndAt', 'datetime', [
                'format' => 'd M y',
                'locale' => 'ru',
                'label' => 'платили ПО',
            ])
            ->add('period', null, [
                'label' => 'общий срок сколько платили',
            ])
            ->add('costOnMonth', null, [
                'label' => 'списано денег за отчетный месяц',
                #'format' => '',
            ])
            ->add('guestsGoToCart', null, [
                'label' => 'CTR (переход на карточку)',
            ])
            ->add('lids', null, [
                'label' => 'CTA (лиды)',
            ])
            ->add('costGoto', null, [
                'label' => 'CPC (стоимость перехода)',
            ])
            ->add('costLid', null, [
                'label' => 'CPA (стоимость лида)',
            ])
            ->add('traffic', null, [
                'label' => 'Источники трафика',
            ])
            ->add('answers', null, [
                'label' => 'Оставили отзывы',
            ])
            ->add('entersInCabinet', null, [
                'label' => 'Заходил в кабинет',
            ]);
    }


}
