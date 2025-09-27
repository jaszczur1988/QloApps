<style>
    #reservation-calendar-grid {
        width: 100%;
        border-collapse: collapse;
        table-layout: fixed;
    }
    #reservation-calendar-grid th,
    #reservation-calendar-grid td {
        border: 1px solid #ddd;
        padding: 8px;
        text-align: center;
        overflow: hidden;
        white-space: nowrap;
    }
    #reservation-calendar-grid th {
        background-color: #f2f2f2;
    }
    #reservation-calendar-grid .room-type-header {
        text-align: left;
        font-weight: bold;
        width: 180px; /* Fixed width for room type names */
        position: sticky;
        left: 0;
        background-color: #f8f8f8;
        z-index: 1;
    }
    #reservation-calendar-grid .calendar-day-cell {
        position: relative;
        height: 50px;
    }
    .booking-block {
        position: absolute;
        top: 2px;
        left: 2px;
        height: calc(100% - 4px);
        background-color: #f0ad4e; /* Default: Warning/Unpaid */
        color: white;
        border-radius: 4px;
        z-index: 2;
        padding: 5px;
        box-sizing: border-box;
        overflow: hidden;
        text-align: left;
        font-size: 12px;
        display: flex;
        align-items: center;
        justify-content: space-between; /* To space out name and icons */
        cursor: pointer;
    }
    .booking-block.status-paid {
        background-color: #5cb85c; /* Success/Paid */
    }
    .booking-block.status-checked-in {
        background-color: #337ab7; /* Primary/Checked-in */
        border: 2px solid #2e6da4;
    }
    .booking-block.status-checked-out {
        background-color: #777; /* Default/Checked-out */
    }
    .booking-block .booking-customer-name {
        font-weight: bold;
    }
    .booking-status-icons {
        display: flex;
        gap: 5px;
    }
    .booking-status-icons i {
        font-size: 14px;
    }
    .ui-draggable-helper {
        z-index: 100 !important;
    }
</style>

<div class="panel">
    <div class="panel-heading">
        <i class="icon-calendar"></i> {l s='Reservation Calendar for' mod='hotelreservationsystem'} {$hotelName} - {dateFormat date=$dateFrom format="F Y"}
    </div>

    {if isset($roomTypes) && $roomTypes}
        <div class="table-responsive">
            <table id="reservation-calendar-grid">
                <thead>
                    <tr>
                        <th class="room-type-header">{l s='Room Type' mod='hotelreservationsystem'}</th>
                        {* Generate headers for each day of the month *}
                        {assign var="currentDate" value=$dateFrom}
                        {assign var="endDate" value=$dateTo}
                        {while $currentDate <= $endDate}
                            <th>
                                {dateFormat date=$currentDate format="D"}<br>
                                {dateFormat date=$currentDate format="j"}
                            </th>
                            {assign var="currentDate" value=strtotime("+1 day", $currentDate)|date_format:"%Y-%m-%d"}
                        {/while}
                    </tr>
                </thead>
                <tbody>
                    {foreach from=$roomTypes item=roomType}
                        <tr>
                            <td class="room-type-header">{$roomType.room_type_name|escape:'html':'UTF-8'}</td>
                            {* Generate empty cells for each day *}
                            {assign var="currentDate" value=$dateFrom}
                            {while $currentDate <= $endDate}
                                <td class="calendar-day-cell droppable-cell" data-date="{$currentDate}" data-roomtype="{$roomType.id_product}">
                                    {* Bookings will be placed here by JavaScript *}
                                </td>
                                {assign var="currentDate" value=strtotime("+1 day", $currentDate)|date_format:"%Y-%m-%d"}
                            {/while}
                        </tr>
                    {/foreach}
                </tbody>
            </table>
        </div>
    {else}
        <div class="alert alert-warning">
            {l s='No room types found for the selected hotel.' mod='hotelreservationsystem'}
        </div>
    {/if}
</div>

<!-- Booking Details Modal -->
<div class="modal fade" id="booking-details-modal" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title">{l s='Booking Details' mod='hotelreservationsystem'}</h4>
            </div>
            <div class="modal-body">
                {* Content will be loaded here via AJAX *}
            </div>
        </div>
    </div>
</div>


<script type="text/javascript">
    $(document).ready(function() {
        if (typeof calendarBookings === 'undefined') {
            return;
        }

        renderCalendarBookings();

        function renderCalendarBookings() {
            $('.booking-block').remove(); // Clear existing blocks before rendering

            if (calendarBookings.length === 0) {
                return;
            }

            const dayCellWidth = $('.calendar-day-cell').first().outerWidth();

            calendarBookings.forEach(function(booking, index) {
                const startDate = new Date(booking.date_from + 'T00:00:00');
                const endDate = new Date(booking.date_to + 'T00:00:00');

                const durationDays = Math.round((endDate - startDate) / (1000 * 60 * 60 * 24));

                if (durationDays <= 0) {
                    return;
                }

                const startCellSelector = `.calendar-day-cell[data-date="${booking.date_from}"][data-roomtype="${booking.id_product}"]`;
                const startCell = $(startCellSelector);

                if (startCell.length) {
                    const bookingBlock = $(`<div class="booking-block" data-booking-id="${booking.id_htl_booking}" data-booking-index="${index}"></div>`);
                    const blockWidth = (dayCellWidth * durationDays) - 4;
                    bookingBlock.css('width', blockWidth + 'px');

                    // Set color based on status
                    if (booking.check_out_status == 1) {
                        bookingBlock.addClass('status-checked-out');
                    } else if (booking.check_in_status == 1) {
                        bookingBlock.addClass('status-checked-in');
                    } else if (booking.is_paid) {
                        bookingBlock.addClass('status-paid');
                    }

                    // Add customer name
                    const customerNameSpan = $(`<span class="booking-customer-name">${booking.customer_name.escapeHtml()}</span>`);
                    bookingBlock.append(customerNameSpan);

                    // Add status icons
                    const statusIcons = $('<div class="booking-status-icons"></div>');
                    if (booking.is_paid) {
                        statusIcons.append('<i class="icon-money" title="{l s="Paid" mod="hotelreservationsystem"}"></i>');
                    }
                    if (booking.check_in_status == 1) {
                        statusIcons.append('<i class="icon-key" title="{l s="Checked-In" mod="hotelreservationsystem"}"></i>');
                    }
                    if (booking.check_out_status == 1) {
                        statusIcons.append('<i class="icon-sign-out" title="{l s="Checked-Out" mod="hotelreservationsystem"}"></i>');
                    }
                    bookingBlock.append(statusIcons);

                    startCell.append(bookingBlock);
                }
            });

            // Make new blocks draggable and clickable
            makeBookingsInteractive();
        }

        function makeBookingsInteractive() {
             $('.booking-block').draggable({
                revert: "invalid",
                containment: "#reservation-calendar-grid",
                helper: "clone",
                start: function(event, ui) {
                    ui.helper.css('width', $(this).width() + 'px');
                }
            }).on('click', function(e) {
                // Prevent click event when dragging
                if ($(this).is('.ui-draggable-dragging')) {
                    return;
                }
                const bookingId = $(this).data('booking-id');

                $.ajax({
                    url: '{$calendar_controller_url|escape:'html':'UTF-8'}&ajax=1&action=getBookingDetails',
                    type: 'POST',
                    dataType: 'json',
                    data: { id_htl_booking: bookingId },
                    success: function(response) {
                        if (response.success) {
                            $('#booking-details-modal .modal-body').html(response.html);
                            $('#booking-details-modal').modal('show');
                        } else {
                            showErrorMessage(response.error);
                        }
                    },
                    error: function() {
                        showErrorMessage('{l s="An error occurred." mod="hotelreservationsystem"}');
                    }
                });
            });
        }

        $('.droppable-cell').droppable({
            accept: ".booking-block",
            hoverClass: "ui-state-hover",
            drop: function(event, ui) {
                const droppedOnCell = $(this);
                const draggedBookingBlock = ui.draggable;
                const bookingId = draggedBookingBlock.data('booking-id');
                const bookingIndex = draggedBookingBlock.data('booking-index');

                const newDate = droppedOnCell.data('date');
                const newRoomType = droppedOnCell.data('roomtype');

                const originalBooking = calendarBookings[bookingIndex];
                if (originalBooking.date_from == newDate && originalBooking.id_product == newRoomType) {
                    return;
                }

                $.ajax({
                    url: '{$calendar_controller_url|escape:'html':'UTF-8'}&ajax=1&action=updateBookingPosition',
                    type: 'POST',
                    dataType: 'json',
                    data: {
                        id_htl_booking: bookingId,
                        new_date_from: newDate,
                        new_id_product: newRoomType
                    },
                    success: function(response) {
                        if (response.success) {
                            const duration = (new Date(originalBooking.date_to) - new Date(originalBooking.date_from));
                            const newStartDate = new Date(newDate + 'T00:00:00');
                            const newEndDate = new Date(newStartDate.getTime() + duration);

                            originalBooking.date_from = newDate;
                            originalBooking.date_to = newEndDate.toISOString().split('T')[0];
                            originalBooking.id_product = newRoomType;

                            renderCalendarBookings();
                            showSuccessMessage('{l s="Booking updated successfully." mod="hotelreservationsystem"}');
                        } else {
                            showErrorMessage('{l s="Failed to update booking:" mod="hotelreservationsystem"} ' + response.error);
                        }
                    },
                    error: function() {
                        showErrorMessage('{l s="An error occurred." mod="hotelreservationsystem"}');
                    }
                });
            }
        });
    });

    String.prototype.escapeHtml = function() {
        var text = document.createTextNode(this);
        var p = document.createElement('p');
        p.appendChild(text);
        return p.innerHTML;
    }
</script>