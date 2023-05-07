module policy::day_of_week {
    use sui::object::{Self, UID};
    use sui::package;
    use sui::tx_context;

    struct UpgradeCap has key, store {
        id: UID,
        cap: package::UpgradeCap,
        day: u8,
    }

    /// Day is not a week day (number in range 0 <= day < 7).
    const ENotWeekDay: u64 = 1;
    // Request to authorize upgrade on the wrong day of the week.
    const ENotAllowedDay: u64 = 2;
    const MS_IN_DAY: u64 = 24 * 60 * 60 * 1000;

    public fun new_policy(
        cap: package::UpgradeCap,
        day: u8,
        ctx: &mut tx_context::TxContext,
    ): UpgradeCap {
        assert!(day < 7, ENotWeekDay);
        UpgradeCap { id: object::new(ctx), cap, day }
    }

    /// This function uses the epoch timestamp from TxContext rather than Clock
    /// because it needs only daily granularity, which means the upgrade
    /// transactions don't require consensus.
    ///
    /// Worth repeating:
    /// > Any transaction that requires access to a Clock must go through
    /// > consensus because the only available instance is a shared object.
    /// >
    /// > As a result, this technique is not suitable for transactions that must
    /// > use the single-owner fast-path
    /// > See Epoch timestamps for a single-owner-compatible source of timestamps.
    fun week_day(ctx: &tx_context::TxContext): u8 {
        let days_since_unix_epoch = tx_context::epoch_timestamp_ms(ctx) / MS_IN_DAY;
        // The unix epoch (1st Jan 1970) was a Thursday; days
        // since the epoch must be shifted by 3 so that 0 = Monday.
        ((days_since_unix_epoch + 3) % 7 as u8)
    }

    public fun authorize_upgrade(
        cap: &mut UpgradeCap,
        policy: u8,
        digest: vector<u8>,
        ctx: &tx_context::TxContext,
    ): package::UpgradeTicket {
        assert!(week_day(ctx) == cap.day, ENotAllowedDay);
        package::authorize_upgrade(&mut cap.cap, policy, digest)
    }

    public fun commit_upgrade(cap: &mut UpgradeCap, receipt: package::UpgradeReceipt) {
        package::commit_upgrade(&mut cap.cap, receipt)
    }

    public entry fun make_immutable(cap: UpgradeCap) {
        let UpgradeCap { id, cap, day: _ } = cap;
        object::delete(id);
        package::make_immutable(cap);
    }
}
