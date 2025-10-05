package com.bean;

import java.util.List;

public class Indent {
    private String indentNumber;
    private String date;
    private String department;
    private String indentedBy;
    private List<IndentItem> items;

    public String getIndentNumber() { return indentNumber; }
    public void setIndentNumber(String indentNumber) { this.indentNumber = indentNumber; }

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getIndentedBy() { return indentedBy; }
    public void setIndentedBy(String indentedBy) { this.indentedBy = indentedBy; }

    public List<IndentItem> getItems() { return items; }
    public void setItems(List<IndentItem> items) { this.items = items; }
}
