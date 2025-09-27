<?php
/**
* NOTICE OF LICENSE
*
* This source file is subject to the Open Software License version 3.0
* that is bundled with this package in the file LICENSE.md
*
* @author Jules - AI Software Engineer
* @copyright Since 2024
* @license https://opensource.org/license/osl-3-0-php Open Software License version 3.0
*/

class AdminDashboardController extends AdminDashboardControllerCore
{
    public function initContent()
    {
        // Redirect to the new Reservation Calendar page instead of showing the default dashboard
        $calendarUrl = $this->context->link->getAdminLink('AdminReservationCalendar');
        Tools::redirectAdmin($calendarUrl);
    }
}