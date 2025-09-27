<div class="container-fluid">
    <div class="row">
        <div class="col-md-6">
            <h4><i class="icon-user"></i> {l s='Guest Information' mod='hotelreservationsystem'}</h4>
            <p><strong>{l s='Name:' mod='hotelreservationsystem'}</strong> {$customer->firstname|escape:'html':'UTF-8'} {$customer->lastname|escape:'html':'UTF-8'}</p>
            <p><strong>{l s='Email:' mod='hotelreservationsystem'}</strong> {$customer->email|escape:'html':'UTF-8'}</p>
        </div>
        <div class="col-md-6">
            <h4><i class="icon-info-circle"></i> {l s='Booking Status' mod='hotelreservationsystem'}</h4>
            <p><strong>{l s='Payment Status:' mod='hotelreservationsystem'}</strong> <span class="label" style="background-color:{$order_status_color};">{$payment_status|escape:'html':'UTF-8'}</span></p>
            <p><strong>{l s='Checked-In:' mod='hotelreservationsystem'}</strong> {if $booking->check_in_status}<i class="icon-check text-success"></i>{else}<i class="icon-times text-danger"></i>{/if}</p>
            <p><strong>{l s='Checked-Out:' mod='hotelreservationsystem'}</strong> {if $booking->check_out_status}<i class="icon-check text-success"></i>{else}<i class="icon-times text-danger"></i>{/if}</p>
        </div>
    </div>
    <hr>
    <h4><i class="icon-calendar"></i> {l s='Stay Details' mod='hotelreservationsystem'}</h4>
    <p><strong>{l s='Room Type:' mod='hotelreservationsystem'}</strong> {$booking->room_type_name|escape:'html':'UTF-8'}</p>
    <p><strong>{l s='From:' mod='hotelreservationsystem'}</strong> {dateFormat date=$booking->date_from format="Y-m-d"}</p>
    <p><strong>{l s='To:' mod='hotelreservationsystem'}</strong> {dateFormat date=$booking->date_to format="Y-m-d"}</p>
    <hr>
    <h4><i class="icon-money"></i> {l s='Financials' mod='hotelreservationsystem'}</h4>
    <p><strong>{l s='Total Price (Tax Excl.):' mod='hotelreservationsystem'}</strong> {displayPrice price=$order->total_paid_tax_excl currency=$currency->id}</p>
    <p><strong>{l s='Total Price (Tax Incl.):' mod='hotelreservationsystem'}</strong> {displayPrice price=$order->total_paid_tax_incl currency=$currency->id}</p>
    <div class="text-right">
        <a href="{$order_link|escape:'html':'UTF-8'}" class="btn btn-primary" target="_blank">
            <i class="icon-search"></i> {l s='View Full Order' mod='hotelreservationsystem'}
        </a>
    </div>
</div>