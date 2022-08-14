.define LED_ADDRESS 0x10
.define SW_ADDRESS 0x30

// Read SW switches and display on LEDs
        mvt   r3, #LED_ADDRESS        // point to LED port
        mvt   r4, #SW_ADDRESS         // point to SW port
MAIN:   ld    r0, [r4]                // read SW values
        st    r0, [r3]                // light up LEDs
        mv    pc, #MAIN
