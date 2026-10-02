/// The one-time "OneSpend Pro" in-app product. Must match the product id in Play Console.
const proProductId = 'onespend_pro';

/// What happened to a purchase of [proProductId] (or another product).
enum ProPurchaseStatus { pending, purchased, restored, error, canceled }

/// A purchase update from the store, reduced to what the app needs.
typedef ProPurchaseEvent = ({String productId, ProPurchaseStatus status});
