<?php

declare(strict_types=1);

namespace Restoclub\AnalyticsBundle\Controller;

use Sonata\AdminBundle\Controller\CRUDController;
use Symfony\Component\HttpFoundation\JsonResponse;

class AnalyticsGuestsRestoratorAdminController extends CRUDController
{
    /**
     * Обновляет данные в таблице отчёта
     * @return JsonResponse
     */
    public function updateReportAction(): JsonResponse
    {
        $sql = <<< END
            SELECT 
                c.site_id,
                s.name AS street,
                c.address_house,
                c.city_id,
                cs.begin_date,
                cs.end_date,
                cs.stopped_at
            FROM client_service cs
            INNER JOIN clients c ON cs.client_id=c.id
            INNER JOIN service s ON cs.service_id=s.id
            INNER JOIN streets st ON c.street_id=st.id
            LIMIT 10 
            END;

        $connection = $this->getDoctrine()->getConnection("crm");
        $statement = $connection->prepare($sql);
        $statement->execute();
        $statement->fetchAll();

        return new JsonResponse([
            'ok' => 1,
        ]);
    }


}
