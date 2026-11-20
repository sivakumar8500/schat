class CouponModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String discountType; // 'percentage' or 'fixed_amount'
  final double discountValue;
  final double minPurchaseAmount;
  final double? maxDiscountAmount;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minPurchaseAmount = 0.0,
    this.maxDiscountAmount,
    this.isActive = true,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minPurchaseAmount: (json['min_purchase_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'description': description,
    'discount_type': discountType,
    'discount_value': discountValue,
    'min_purchase_amount': minPurchaseAmount,
    'max_discount_amount': maxDiscountAmount,
    'is_active': isActive,
  };
}

class CouponValidationResult {
  final bool valid;
  final String code;
  final String name;
  final String discountType;
  final double discountValue;
  final double minPurchaseAmount;
  final double? maxDiscountAmount;
  final double originalPrice;
  final double discountAmount;
  final double finalPrice;
  final String message;

  const CouponValidationResult({
    required this.valid,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.minPurchaseAmount = 0.0,
    this.maxDiscountAmount,
    required this.originalPrice,
    required this.discountAmount,
    required this.finalPrice,
    required this.message,
  });

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    return CouponValidationResult(
      valid: json['valid'] as bool? ?? false,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minPurchaseAmount: (json['min_purchase_amount'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      message: json['message']?.toString() ?? '',
    );
  }
}

class RazorpayOrderModel {
  final String id;
  final int amount; // in paise
  final String currency;
  final String planId;
  final String? keyId;
  final double discountAmount;
  final double? finalAmount;
  final String? couponCode;

  const RazorpayOrderModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.planId,
    this.keyId,
    this.discountAmount = 0.0,
    this.finalAmount,
    this.couponCode,
  });

  factory RazorpayOrderModel.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      planId: json['plan_id']?.toString() ?? '',
      keyId: json['key_id']?.toString(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['final_amount'] as num?)?.toDouble(),
      couponCode: json['coupon_code']?.toString(),
    );
  }
}
