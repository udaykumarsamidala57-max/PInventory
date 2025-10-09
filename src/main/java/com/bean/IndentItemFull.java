package com.bean;

import java.sql.Date;

public class IndentItemFull {
    private int id;
    private String indentNo;
    private Date date;
    private String itemName;
    private double qty;
    private double balanceQty;
    private String uom;
    private String department;
    private String requestedBy;
    private String purpose;
    private String istatus;
    private String approvedBy;
    private Date iapprovevdate;
    private String status;
    private Date fapprovevdate;
    private String indentNext;
    private int itemId; // needed for validation joins

    // --- Getters and Setters ---

    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }

    public String getIndentNo() {
        return indentNo;
    }
    public void setIndentNo(String indentNo) {
        this.indentNo = indentNo;
    }

    public Date getDate() {
        return date;
    }
    public void setDate(Date date) {
        this.date = date;
    }

    public String getItemName() {
        return itemName;
    }
    public void setItemName(String itemName) {
        this.itemName = itemName;
    }

    public double getQty() {
        return qty;
    }
    public void setQty(double qty) {
        this.qty = qty;
    }

    public double getBalanceQty() {
        return balanceQty;
    }
    public void setBalanceQty(double balanceQty) {
        this.balanceQty = balanceQty;
    }

    public String getUom() {
        return uom;
    }
    public void setUom(String uom) {
        this.uom = uom;
    }

    public String getDepartment() {
        return department;
    }
    public void setDepartment(String department) {
        this.department = department;
    }

    public String getRequestedBy() {
        return requestedBy;
    }
    public void setRequestedBy(String requestedBy) {
        this.requestedBy = requestedBy;
    }

    public String getPurpose() {
        return purpose;
    }
    public void setPurpose(String purpose) {
        this.purpose = purpose;
    }

    public String getIstatus() {
        return istatus;
    }
    public void setIstatus(String istatus) {
        this.istatus = istatus;
    }

    public String getApprovedBy() {
        return approvedBy;
    }
    public void setApprovedBy(String approvedBy) {
        this.approvedBy = approvedBy;
    }

    public Date getIapprovevdate() {
        return iapprovevdate;
    }
    public void setIapprovevdate(Date iapprovevdate) {
        this.iapprovevdate = iapprovevdate;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public Date getFapprovevdate() {
        return fapprovevdate;
    }
    public void setFapprovevdate(Date fapprovevdate) {
        this.fapprovevdate = fapprovevdate;
    }

    public String getIndentNext() {
        return indentNext;
    }
    public void setIndentNext(String indentNext) {
        this.indentNext = indentNext;
    }

    public int getItemId() {
        return itemId;
    }
    public void setItemId(int itemId) {
        this.itemId = itemId;
    }
}
