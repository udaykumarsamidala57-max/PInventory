package com.bean;

import java.math.BigDecimal;

public class AggregatedItem {
    private String description;
    private double qty = 0.0;
    private BigDecimal rate = BigDecimal.ZERO;
    private BigDecimal amount = BigDecimal.ZERO;
    private BigDecimal discountPercent = BigDecimal.ZERO;
    private BigDecimal discountValue = BigDecimal.ZERO;
    private BigDecimal gstPercent = BigDecimal.ZERO;
    private BigDecimal gstValue = BigDecimal.ZERO;
    private BigDecimal netAmount = BigDecimal.ZERO;

    // Getters & Setters
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public double getQty() { return qty; }
    public void setQty(double qty) { this.qty = qty; }

    public BigDecimal getRate() { return rate; }
    public void setRate(BigDecimal rate) { this.rate = rate; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public BigDecimal getDiscountPercent() { return discountPercent; }
    public void setDiscountPercent(BigDecimal discountPercent) { this.discountPercent = discountPercent; }

    public BigDecimal getDiscountValue() { return discountValue; }
    public void setDiscountValue(BigDecimal discountValue) { this.discountValue = discountValue; }

    public BigDecimal getGstPercent() { return gstPercent; }
    public void setGstPercent(BigDecimal gstPercent) { this.gstPercent = gstPercent; }

    public BigDecimal getGstValue() { return gstValue; }
    public void setGstValue(BigDecimal gstValue) { this.gstValue = gstValue; }

    public BigDecimal getNetAmount() { return netAmount; }
    public void setNetAmount(BigDecimal netAmount) { this.netAmount = netAmount; }
}
