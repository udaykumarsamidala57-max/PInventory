<%@ page language="java"
         contentType="text/html; charset=UTF-8"
         pageEncoding="UTF-8"
         isELIgnored="false" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<%
    HttpSession sess = request.getSession(false);

    if (sess == null || sess.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String user = (String) sess.getAttribute("username");
    String role = (String) sess.getAttribute("role");
    String dept = (String) sess.getAttribute("department");
%>

<!DOCTYPE html>
<html lang="en">

<head>

    <meta charset="UTF-8">

    <title>Dining Hall Consumption Form</title>

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap"
          rel="stylesheet">

    <link rel="stylesheet"
          href="CSS/Form.css">

    <style>

        /* =========================================================
           FORM CONTROLS
        ========================================================= */

        select {
            width: 180px;
            max-height: 180px;
            overflow-y: auto;
        }

        .main-table select {
            padding: 4px;
            font-size: 14px;
        }


        /* =========================================================
           STOCK STATUS
        ========================================================= */

        .stock-unavailable {
            color: red;
            font-weight: 600;
        }

        .stock-available {
            color: green;
            font-weight: 600;
        }


        /* =========================================================
           DISABLED QUANTITY
        ========================================================= */

        .qty:disabled {
            background-color: #f8d7da;
            cursor: not-allowed;
        }


        /* =========================================================
           TABLE IMPROVEMENTS
        ========================================================= */

        #itemsTable {
            width: 100%;
            border-collapse: collapse;
        }

        #itemsTable th,
        #itemsTable td {
            padding: 7px;
            vertical-align: middle;
        }

        #itemsTable select,
        #itemsTable input {
            box-sizing: border-box;
        }

        #itemsTable .cat,
        #itemsTable .subcat,
        #itemsTable .item {
            width: 100%;
        }

        #itemsTable .qty,
        #itemsTable .remarks {
            width: 100%;
        }

        .uom,
        .stock {
            text-align: center;
            white-space: nowrap;
        }


        /* =========================================================
           BUTTON AREA
        ========================================================= */

        .button-area {
            margin-top: 15px;
            text-align: center;
        }

        .button-area button {
            margin: 3px;
        }


        /* =========================================================
           EMPTY TABLE MESSAGE
        ========================================================= */

        .empty-row td {
            text-align: center;
            color: #777;
            padding: 15px;
        }

    </style>

</head>


<body>

<%@ include file="header.jsp" %>


<div class="main-content">

    <div class="card">

        <h2 align="center">
            DINING HALL CONSUMPTION FORM
        </h2>


        <!-- =====================================================
             FORM
        ====================================================== -->

        <form action="DiningHallServlet"
              method="post"
              id="diningForm">


            <!-- =================================================
                 HEADER INFORMATION
            ================================================== -->

            <table class="main-table">

                <tr>

                    <td>
                        <label for="issueno">
                            Issue No:
                        </label>
                    </td>

                    <td>
                        <input type="text"
                               id="issueno"
                               name="issueno"
                               value="${nextIssueNo}"
                               readonly>
                    </td>

                </tr>


                <tr>

                    <td>
                        <label>
                            Department:
                        </label>
                    </td>

                    <td>

                        <input type="hidden"
                               name="department"
                               value="Dining Hall">

                        <b>Dining Hall</b>

                    </td>

                </tr>


                <tr>

                    <td>
                        <label for="issued_to">
                            Issued To:
                        </label>
                    </td>

                    <td>

                        <input type="text"
                               id="issued_to"
                               name="issued_to"
                               required>

                    </td>

                </tr>


                <tr>

                    <td>
                        <label for="session">
                            Session:
                        </label>
                    </td>

                    <td>

                        <select name="session"
                                id="session"
                                required>

                            <option value="">
                                -- Select --
                            </option>

                            <option value="Morning Drink">
                                Morning Drink
                            </option>

                            <option value="Break Fast">
                                Break Fast
                            </option>

                            <option value="Lunch">
                                Lunch
                            </option>

                            <option value="Snacks">
                                Snacks
                            </option>

                            <option value="Dinner">
                                Dinner
                            </option>

                            <option value="Staff Tea">
                                Staff Tea
                            </option>

                            <option value="Special Event">
                                Special Event
                            </option>


                            <%
                                if ("Global".equalsIgnoreCase(role)) {
                            %>

                                <option value="Adjustment">
                                    Adjustment
                                </option>

                            <%
                                }
                            %>

                        </select>

                    </td>

                </tr>


                <tr>

                    <td>
                        <label for="issue_date">
                            Issue Date:
                        </label>
                    </td>

                    <td>

                        <input type="date"
                               name="issue_date"
                               id="issue_date"
                               required>

                    </td>

                </tr>

            </table>


            <br>


            <!-- =================================================
                 ITEMS TABLE
            ================================================== -->

            <table border="1"
                   id="itemsTable"
                   class="main-table">

                <thead>

                    <tr>

                        <th>
                            Category
                        </th>

                        <th>
                            SubCategory
                        </th>

                        <th>
                            Item
                        </th>

                        <th>
                            UOM
                        </th>

                        <th>
                            Available Stock
                        </th>

                        <th>
                            Qty Issued
                        </th>

                        <th>
                            Remarks
                        </th>

                        <th>
                            Action
                        </th>

                    </tr>

                </thead>


                <tbody>

                    <!-- Dynamic rows will be added here -->

                </tbody>

            </table>


            <!-- =================================================
                 BUTTONS
            ================================================== -->

            <div class="button-area">

                <button type="button"
                        id="addItemBtn"
                        class="btn btn-info">

                    ➕ Add Item

                </button>


                <button type="submit"
                        class="btn btn-green">

                    ✅ Submit Consumption

                </button>

            </div>


        </form>

    </div>

</div>



<script>

document.addEventListener("DOMContentLoaded", function () {


    /* =========================================================
       SET TODAY'S DATE
    ========================================================= */

    const issueDate =
        document.getElementById("issue_date");

    if (issueDate) {

        const today =
            new Date().toISOString().split("T")[0];

        issueDate.value = today;
    }



    /* =========================================================
       MASTER DATA FROM SERVLET
    ========================================================= */

    const categories = [];

    <c:forEach var="c"
               items="${masterData.categories}">

        categories.push({
            name: '${c.name}',
            departmentName: '${c.departmentName}'
        });

    </c:forEach>



    const subcategories = [];

    <c:forEach var="s"
               items="${masterData.subcategories}">

        subcategories.push({
            name: '${s.name}',
            categoryName: '${s.categoryName}'
        });

    </c:forEach>



    const items = [];

    <c:forEach var="i"
               items="${masterData.items}">

        items.push({
            id: '${i.id}',
            name: '${i.name}',
            UOM: '${i.UOM}',
            category: '${i.category}',
            subcategory: '${i.subcategory}',
            stock: '${i.stock}'
        });

    </c:forEach>



    /* =========================================================
       ADD ITEM BUTTON
    ========================================================= */

    document
        .getElementById("addItemBtn")
        .addEventListener("click", function () {

            addRow();

        });



    /* =========================================================
       ADD NEW ITEM ROW
    ========================================================= */

    function addRow() {


        const tbody =
            document.querySelector("#itemsTable tbody");


        const tr =
            document.createElement("tr");


        tr.innerHTML = `

            <td>

                <select class="cat">

                    <option value="">
                        -- Select Category --
                    </option>

                </select>

            </td>


            <td>

                <select class="subcat">

                    <option value="">
                        -- Select SubCategory --
                    </option>

                </select>

            </td>


            <td>

                <select class="item"
                        name="item_id">

                    <option value="">
                        -- Select Item --
                    </option>

                </select>

            </td>


            <td class="uom">
            </td>


            <td class="stock">
            </td>


            <td>

                <input type="number"
                       name="qty_issued"
                       class="qty"
                       min="0"
                       step="any"
                       required>

            </td>


            <td>

                <input type="text"
                       name="remarks"
                       class="remarks">

            </td>


            <td>

                <button type="button"
                        class="btn btn-red removeBtn">

                    Remove

                </button>

            </td>

        `;


        tbody.appendChild(tr);



        /* =====================================================
           ROW ELEMENTS
        ====================================================== */

        const catSel =
            tr.querySelector(".cat");


        const subSel =
            tr.querySelector(".subcat");


        const itemSel =
            tr.querySelector(".item");


        const uomCell =
            tr.querySelector(".uom");


        const stockCell =
            tr.querySelector(".stock");


        const qtyInput =
            tr.querySelector(".qty");


        const removeBtn =
            tr.querySelector(".removeBtn");



        /* =====================================================
           UNIQUE CATEGORIES
        ====================================================== */

        const uniqueCats =
            [...new Set(
                categories.map(function (c) {
                    return c.name;
                })
            )];


        catSel.innerHTML =
            '<option value="">-- Select Category --</option>';


        uniqueCats.forEach(function (name) {

            catSel.add(
                new Option(name, name)
            );

        });



        /* =====================================================
           CATEGORY CHANGE
        ====================================================== */

        catSel.addEventListener(
            "change",
            function () {


                subSel.innerHTML =
                    '<option value="">-- Select SubCategory --</option>';


                subcategories
                    .filter(function (s) {

                        return s.categoryName ===
                               catSel.value;

                    })
                    .forEach(function (s) {

                        subSel.add(
                            new Option(
                                s.name,
                                s.name
                            )
                        );

                    });


                itemSel.innerHTML =
                    '<option value="">-- Select Item --</option>';


                uomCell.textContent = "";

                stockCell.textContent = "";

                stockCell.classList.remove(
                    "stock-unavailable"
                );

                stockCell.classList.remove(
                    "stock-available"
                );

                qtyInput.value = "";

                qtyInput.disabled = false;

            }
        );



        /* =====================================================
           SUBCATEGORY CHANGE
        ====================================================== */

        subSel.addEventListener(
            "change",
            function () {


                itemSel.innerHTML =
                    '<option value="">-- Select Item --</option>';


                items
                    .filter(function (item) {

                        return item.category === catSel.value &&
                               item.subcategory === subSel.value;

                    })
                    .forEach(function (item) {


                        const option =
                            new Option(
                                item.name,
                                item.id
                            );


                        option.dataset.uom =
                            item.UOM || "";


                        option.dataset.stock =
                            item.stock || "0";


                        itemSel.add(option);

                    });


                uomCell.textContent = "";

                stockCell.textContent = "";

                stockCell.classList.remove(
                    "stock-unavailable"
                );

                stockCell.classList.remove(
                    "stock-available"
                );

                qtyInput.value = "";

                qtyInput.disabled = false;

            }
        );



        /* =====================================================
           ITEM CHANGE
        ====================================================== */

        itemSel.addEventListener(
            "change",
            function () {


                const selectedOption =
                    itemSel.options[
                        itemSel.selectedIndex
                    ];


                if (!selectedOption ||
                    !selectedOption.value) {

                    uomCell.textContent = "";

                    stockCell.textContent = "";

                    stockCell.classList.remove(
                        "stock-unavailable"
                    );

                    stockCell.classList.remove(
                        "stock-available"
                    );

                    qtyInput.value = "";

                    qtyInput.disabled = false;

                    return;
                }


                const stock =
                    parseFloat(
                        selectedOption.dataset.stock || "0"
                    );


                const uom =
                    selectedOption.dataset.uom || "";


                uomCell.textContent =
                    uom;


                if (stock > 0) {

                    stockCell.textContent =
                        stock;


                    stockCell.classList.remove(
                        "stock-unavailable"
                    );


                    stockCell.classList.add(
                        "stock-available"
                    );


                    qtyInput.disabled = false;


                } else {


                    stockCell.textContent =
                        "Stock Not Available";


                    stockCell.classList.remove(
                        "stock-available"
                    );


                    stockCell.classList.add(
                        "stock-unavailable"
                    );


                    qtyInput.disabled = true;

                    qtyInput.value = "";


                    alert(
                        "⚠️ Stock not available for this item! " +
                        "Please remove or choose another item."
                    );

                }

            }
        );



        /* =====================================================
           QUANTITY VALIDATION
        ====================================================== */

        qtyInput.addEventListener(
            "input",
            function () {


                const selectedOption =
                    itemSel.options[
                        itemSel.selectedIndex
                    ];


                if (!selectedOption ||
                    !selectedOption.value) {

                    return;
                }


                const stock =
                    parseFloat(
                        selectedOption.dataset.stock || "0"
                    );


                const qty =
                    parseFloat(
                        qtyInput.value || "0"
                    );


                if (qty < 0) {

                    qtyInput.value = "";

                    return;
                }


                if (qty > stock) {

                    alert(
                        "⚠️ Quantity issued cannot be " +
                        "greater than available stock!"
                    );


                    qtyInput.value = "";

                }

            }
        );



        /* =====================================================
           REMOVE ROW
        ====================================================== */

        removeBtn.addEventListener(
            "click",
            function () {

                tr.remove();

            }
        );

    }



    /* =========================================================
       FORM SUBMIT VALIDATION
    ========================================================= */

    document
        .getElementById("diningForm")
        .addEventListener("submit", function (event) {


            const rows =
                document.querySelectorAll(
                    "#itemsTable tbody tr"
                );


            /* ================================================
               AT LEAST ONE ITEM
            ================================================= */

            if (rows.length === 0) {

                alert(
                    "⚠️ Please add at least one item."
                );


                event.preventDefault();

                return;

            }



            let invalid =
                false;



            /* ================================================
               VALIDATE EACH ROW
            ================================================= */

            rows.forEach(function (tr) {


                const itemSelect =
                    tr.querySelector(".item");


                const qtyInput =
                    tr.querySelector(".qty");


                const stockCell =
                    tr.querySelector(".stock");


                const itemId =
                    itemSelect.value.trim();


                const qty =
                    parseFloat(
                        qtyInput.value || "0"
                    );


                const stock =
                    parseFloat(
                        itemSelect
                            .options[
                                itemSelect.selectedIndex
                            ]
                            ?.dataset.stock || "0"
                    );


                /* ============================================
                   ITEM REQUIRED
                ============================================ */

                if (!itemId) {

                    invalid = true;

                    alert(
                        "⚠️ Please select an item in every row."
                    );

                    return;

                }



                /* ============================================
                   STOCK REQUIRED
                ============================================ */

                if (stock <= 0) {

                    invalid = true;

                    alert(
                        "⚠️ Selected item has no available stock."
                    );

                    return;

                }



                /* ============================================
                   QUANTITY REQUIRED
                ============================================ */

                if (isNaN(qty) || qty <= 0) {

                    invalid = true;

                    alert(
                        "⚠️ Quantity must be greater than zero."
                    );

                    return;

                }



                /* ============================================
                   QUANTITY CANNOT EXCEED STOCK
                ============================================ */

                if (qty > stock) {

                    invalid = true;

                    alert(
                        "⚠️ Quantity issued cannot be greater " +
                        "than available stock."
                    );

                    return;

                }

            });



            /* ================================================
               STOP SUBMISSION
            ================================================= */

            if (invalid) {

                event.preventDefault();

                return;

            }



            /* ================================================
               FINAL CONFIRMATION
            ================================================= */

            const confirmed =
                confirm(
                    "Are you sure you want to submit this " +
                    "Dining Hall consumption transaction?"
                );


            if (!confirmed) {

                event.preventDefault();

            }

        });

});

</script>


</body>

</html>