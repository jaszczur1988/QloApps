<?php
/**
* NOTICE OF LICENSE
*
* This source file is subject to the Open Software License version 3.0
* that is bundled with this package in the file LICENSE.md
* It is also available through the world-wide-web at this URL:
* https://opensource.org/license/osl-3-0-php
*
* @author Jules - AI Software Engineer
* @copyright Since 2024
* @license https://opensource.org/license/osl-3-0-php Open Software License version 3.0
*/

class AdminReservationCalendarController extends ModuleAdminController
{
    public function __construct()
    {
        $this->bootstrap = true;
        $this->context = Context::getContext();

        parent::__construct();
        $this->toolbar_title = $this->l('Reservation Calendar');
    }

    public function setMedia()
    {
        parent::setMedia();
        $this->addJqueryUI(array('ui.draggable', 'ui.droppable'));
    }

    public function initContent()
    {
        parent::initContent();

        $this->fetchAndAssignCalendarData();

        $this->content = $this->context->smarty->fetch(
            _PS_MODULE_DIR_.$this->module->name.'/views/templates/admin/reservation_calendar.tpl'
        );

        $this->context->smarty->assign(array(
            'content' => $this->content,
        ));
    }

    public function ajaxProcessGetBookingDetails()
    {
        $id_htl_booking = (int)Tools::getValue('id_htl_booking');
        if (!$id_htl_booking) {
            $this->ajaxDie(json_encode(['success' => false, 'error' => $this->l('Invalid booking ID.')]));
        }

        $booking = new HotelBookingDetail($id_htl_booking);
        if (!Validate::isLoadedObject($booking)) {
            $this->ajaxDie(json_encode(['success' => false, 'error' => $this->l('Booking not found.')]));
        }

        $order = new Order($booking->id_order);
        $customer = new Customer($order->id_customer);
        $currency = new Currency($order->id_currency);
        $orderState = new OrderState($order->current_state, $this->context->language->id);

        $this->context->smarty->assign([
            'booking' => $booking,
            'order' => $order,
            'customer' => $customer,
            'currency' => $currency,
            'payment_status' => $orderState->name,
            'order_link' => $this->context->link->getAdminLink('AdminOrders', true, [], ['vieworder' => '', 'id_order' => $order->id])
        ]);

        $modalContent = $this->context->smarty->fetch(
            _PS_MODULE_DIR_.$this->module->name.'/views/templates/admin/_partials/booking_details.tpl'
        );

        $this->ajaxDie(json_encode(['success' => true, 'html' => $modalContent]));
    }

    public function ajaxProcessUpdateBookingPosition()
    {
        $id_htl_booking = (int)Tools::getValue('id_htl_booking');
        $new_date_from_str = Tools::getValue('new_date_from');
        $new_id_product = (int)Tools::getValue('new_id_product');

        if (!$id_htl_booking || !$new_date_from_str || !$new_id_product) {
            $this->ajaxDie(json_encode(array('success' => false, 'error' => $this->l('Missing parameters.'))));
        }

        $booking = new HotelBookingDetail($id_htl_booking);
        if (!Validate::isLoadedObject($booking)) {
            $this->ajaxDie(json_encode(array('success' => false, 'error' => $this->l('Booking not found.'))));
        }

        // Calculate duration and new end date
        $date_from_dt = new DateTime($booking->date_from);
        $date_to_dt = new DateTime($booking->date_to);
        $duration = $date_from_dt->diff($date_to_dt);

        $new_date_from_dt = new DateTime($new_date_from_str);
        $new_date_to_dt = clone $new_date_from_dt;
        $new_date_to_dt->add($duration);

        $new_date_to_str = $new_date_to_dt->format('Y-m-d');

        // Check for availability, excluding the current booking being moved
        $isAvailable = $this->isRoomTypeAvailable($new_id_product, $booking->id_hotel, $new_date_from_str, $new_date_to_str, $id_htl_booking);

        if ($isAvailable) {
            $booking->id_product = $new_id_product;
            $booking->date_from = $new_date_from_str . ' 00:00:00';
            $booking->date_to = $new_date_to_str . ' 00:00:00';

            // We need to find a new specific room of the new type
            $availableRooms = $booking->getAvailableRoomsForReallocation($booking->date_from, $booking->date_to, $new_id_product, $booking->id_hotel);
            if ($availableRooms) {
                $booking->id_room = $availableRooms[0]['id_room'];
                $booking->room_type_name = (new Product($new_id_product, false, $this->context->language->id))->name;

                if ($booking->update()) {
                    // Price difference is ignored for now as per plan
                    $this->ajaxDie(json_encode(array('success' => true)));
                }
            }
        }

        $this->ajaxDie(json_encode(array('success' => false, 'error' => $this->l('The selected room/date is not available.'))));
    }

    private function isRoomTypeAvailable($id_product, $id_hotel, $date_from, $date_to, $exclude_id_htl_booking)
    {
        $total_rooms = HotelRoomInformation::getHotelRoomsCount($id_hotel, $id_product);
        if (!$total_rooms) {
            return false;
        }

        $booked_rooms_by_date = HotelBookingDetail::getBookedRoomsForDateRange($date_from, $date_to, $id_hotel, $id_product);

        $current_date = new DateTime($date_from);
        $end_date = new DateTime($date_to);

        while ($current_date < $end_date) {
            $date_str = $current_date->format('Y-m-d');
            $booked_count = 0;
            if (isset($booked_rooms_by_date[$date_str])) {
                 foreach ($booked_rooms_by_date[$date_str] as $booking) {
                    if ($booking['id_htl_booking'] != $exclude_id_htl_booking) {
                        $booked_count++;
                    }
                }
            }
            if ($booked_count >= $total_rooms) {
                return false;
            }
            $current_date->modify('+1 day');
        }

        return true;
    }

    private function fetchAndAssignCalendarData()
    {
        $objHotelBranchInformation = new HotelBranchInformation();
        $hotelBranchesInfo = $objHotelBranchInformation->hotelBranchesInfo(false, 1);
        $hotelBranchesInfo = HotelBranchInformation::filterDataByHotelAccess(
            $hotelBranchesInfo,
            $this->context->employee->id_profile,
            'id'
        );

        if ($hotelBranchesInfo) {
            $id_hotel = reset($hotelBranchesInfo)['id'];
            $dateFrom = date('Y-m-01');
            $dateTo = date('Y-m-t');

            $objRoomType = new HotelRoomType();
            $roomTypes = $objRoomType->getRoomTypeByHotelId($id_hotel, $this->context->language->id, 1);

            $bookings = $this->getCalendarBookings($dateFrom, $dateTo, $id_hotel);

            $this->context->smarty->assign(array(
                'roomTypes' => $roomTypes,
                'dateFrom' => $dateFrom,
                'dateTo' => $dateTo,
                'hotelName' => (new HotelBranchInformation($id_hotel, $this->context->language->id))->hotel_name,
                'calendar_controller_url' => $this->context->link->getAdminLink('AdminReservationCalendar'),
            ));

            Media::addJsDef(array(
                'calendarBookings' => $bookings,
            ));
        }
    }

    private function getCalendarBookings($dateFrom, $dateTo, $id_hotel)
    {
        $objBookingDetail = new HotelBookingDetail();
        $bookingParams = array(
            'date_from' => $dateFrom,
            'date_to' => $dateTo,
            'hotel_id' => $id_hotel,
            'id_room_type' => 0,
            'search_booked' => 1,
            'search_unavai' => 0,
            'search_partial' => 0,
            'search_available' => 0,
            'search_cart_rms' => 0,
        );
        $rawBookingData = $objBookingDetail->getBookingData($bookingParams);

        $bookings = array();
        if (isset($rawBookingData['rm_data']) && $rawBookingData['rm_data']) {
            foreach ($rawBookingData['rm_data'] as $roomTypeData) {
                if (isset($roomTypeData['data']['booked']) && $roomTypeData['data']['booked']) {
                    foreach ($roomTypeData['data']['booked'] as $room) {
                        if (isset($room['detail']) && $room['detail']) {
                            foreach ($room['detail'] as $bookingDetail) {
                                $customer = new Customer($bookingDetail['id_customer']);
                                $order = new Order($bookingDetail['id_order']);
                                $payment_status = (new OrderState($order->getCurrentState(), $this->context->language->id))->name;
                                $htlBooking = new HotelBookingDetail($bookingDetail['id_htl_booking']);

                                $bookings[] = array(
                                    'id_product' => $bookingDetail['id_product'],
                                    'date_from' => date('Y-m-d', strtotime($bookingDetail['date_from'])),
                                    'date_to' => date('Y-m-d', strtotime($bookingDetail['date_to'])),
                                    'customer_name' => $customer->firstname.' '.$customer->lastname,
                                    'id_order' => $bookingDetail['id_order'],
                                    'id_htl_booking' => $bookingDetail['id_htl_booking'],
                                    'payment_status' => $payment_status,
                                    'check_in_status' => $htlBooking->check_in_status,
                                    'check_out_status' => $htlBooking->check_out_status,
                                    'is_paid' => $order->hasBeenPaid(),
                                );
                            }
                        }
                    }
                }
            }
        }
        return $bookings;
    }
}