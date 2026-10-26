package com.officecentral.common.web;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * The Settings Master sidebar: one list used by header.jsp (sidebar) and settings.jsp (overview cards).
 * Adding a master page = one line here (and its address in AccessFilter).
 */
public final class SettingsMenu {

    /** One page of the Settings Master. */
    public static final class Page {
        public final String group, key, title, icon, tone, description;
        final List<String> paths;   // servlet paths that belong to this page (new, old and .jsp addresses)

        Page(String group, String key, String title, String icon, String tone, String description, String... paths) {
            this.group = group;
            this.key = key;
            this.title = title;
            this.icon = icon;
            this.tone = tone;
            this.description = description;
            this.paths = Arrays.asList(paths);
        }

        public String getGroup() { return group; }
        public String getKey() { return key; }
        public String getTitle() { return title; }
        public String getIcon() { return icon; }
        public String getTone() { return tone; }
        public String getDescription() { return description; }
    }

    public static final List<Page> PAGES = Collections.unmodifiableList(Arrays.asList(
        new Page("Items", "items", "Item Master", "fa-solid fa-box", "primary",
                 "Add and edit items, categories and units.", "/items", "/ItemsMaster.jsp"),
        new Page("Items", "item-cost", "Item Cost", "fa-solid fa-indian-rupee-sign", "success",
                 "Cost per unit incl. GST, from approved POs or entered manually.", "/item-cost"),
        new Page("Stock", "add-stock", "Add Stock", "fa-solid fa-square-plus", "success",
                 "Add opening or manual stock.", "/add-stock", "/AddStock", "/Addstock.jsp"),
        new Page("Stock", "wastage", "Damage / Wastage Entry", "fa-solid fa-trash-can", "danger",
                 "Write off damaged, expired or lost stock.", "/wastage"),
        new Page("Stock", "stock-audit", "New Audit", "fa-solid fa-clipboard-check", "success",
                 "Record a physical stock count.", "/stock-audit", "/StockVerificationServlet", "/stock_verification.jsp"),
        new Page("Stock", "stock-audit-report", "Audit Report", "fa-solid fa-chart-bar", "info",
                 "Compare physical counts with system stock.", "/stock-audit-report", "/StockAuditReportServlet",
                 "/stock_audit_report.jsp"),
        new Page("Dining Hall", "menu-items", "Dining Hall Menu Config", "fa-solid fa-utensils", "warning",
                 "Set the items used for each day's menu.", "/menu-items", "/MenuItemsServlet", "/menu/menu_items.jsp")
    ));

    private SettingsMenu() { }

    /** The page for this servlet path, "settings" for the overview, or null when it is not a settings page. */
    public static String keyFor(String servletPath) {
        if ("/settings".equals(servletPath)) return "settings";
        for (Page p : PAGES) if (p.paths.contains(servletPath)) return p.key;
        return null;
    }
}
