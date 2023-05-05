/// Example module, testing `sui::clock`.
///
/// From https://docs.sui.io/build/move/time#the-suiclockclock-module
module first_package::clock {
    #[test]
    fun creating_a_clock_and_incrementing_it() {
        use sui::clock::Self;
        use sui::test_scenario as ts;
        use std::debug;

        let ts = ts::begin(@0x1);
        let ctx = ts::ctx(&mut ts);

        let clock = clock::create_for_testing(ctx);

        clock::increment_for_testing(&mut clock, 20);
        clock::increment_for_testing(&mut clock, 22);
        let timestamp = clock::timestamp_ms(&clock);
        assert!(timestamp == 42, 0);
        debug::print(&std::string::utf8(b"Timestamp is: "));
        debug::print(&timestamp);

        clock::destroy_for_testing(clock);
        ts::end(ts);
    }

}
