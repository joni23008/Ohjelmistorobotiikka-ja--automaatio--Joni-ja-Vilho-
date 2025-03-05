*** Settings ***
Library    OperatingSystem
Library    String
Library    Collections
Library    DatabaseLibrary
Library    DateTime
Library    validate.py

*** Variables ***
${PATH}    C:\\Users\\Vilho\\OneDrive\\Desktop\\Gitit\\Ohjelmistorobotiikka-ja--automaatio--Joni-ja-Vilho-\\RF\\

# database variables
${dbname}    rpa
${dbuser}    robotuser
${dbpass}    password
${dbhost}    localhost
${dbport}    3306

*** Keywords ***
Make Connection
    [Arguments]    ${dbtoconnect}
    Connect To Database    pymysql    ${dbtoconnect}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}

*** Keywords ***
Add Invoice Header to DB
    [Arguments]    ${items}
    Make Connection    ${dbname}

    ${invoice_date}=    Convert Date    ${items}[4]    date_format=%d.%m.%Y    result_format=%Y-%m-%d
    ${due_date}=    Convert Date    ${items}[5]    date_format=%d.%m.%Y    result_format=%Y-%m-%d

    ${insertStmt}=    Set Variable    insert into invoice_header (invoice_number, company_name, company_code, reference_number, invoice_date, due_date, bank_account_number, amount_exclude_vat, vat, total_amount, invoice_status_id, comments) values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    @{params}=    Create List    ${items}[0]    ${items}[1]    ${items}[2]    ${items}[3]    ${invoice_date}    ${due_date}    ${items}[6]    ${items}[7]    ${items}[8]    ${items}[9]    -1    'Processing'
    
    Log    ${insertStmt}
    Execute Sql String    ${insertStmt}    parameters=${params}


    Disconnect From Database

*** Keywords ***
Add InvoiceRow to DB
    [Arguments]    ${items}
    Make Connection    ${dbname}

    ${insertStmt}=    Set Variable    insert into invoice_row (invoice_number, rownumber, description, quantity, unit, unit_price, vat_percent, vat, total) values (%s, %s, %s, %s, %s, %s, %s, %s, %s);
    @{params}=    Create List    ${items}[0]    ${items}[1]    ${items}[2]    ${items}[3]    ${items}[4]    ${items}[5]    ${items}[6]    ${items}[7]    ${items}[8]
    Log    ${insertStmt}
    Execute Sql String    ${insertStmt}    parameters=${params}

    Disconnect From Database

*** Tasks ***
Read CSV file to list and add data to database
    Make Connection    ${dbname}
    ${outputHeader}=    Get File    ${PATH}CSV\\InvoiceHeaderData.csv
    ${outputRows}=    Get File    ${PATH}CSV\\InvoiceRowData.csv
    Log    ${outputHeader}
    Log    ${outputRows}

    #   each row read as an element to list
    @{headers}=    Split String    ${outputHeader}    \n
    @{rows}=    Split String    ${outputRows}    \n

    #remove first- and last row from list
    ${length}=    Get Length    ${headers}
    ${length}=    Evaluate    ${length}-1
    ${index}=    Convert To Integer    0

    Remove From List    ${headers}    ${length}
    Remove From List    ${headers}    ${index}
    
    #next for rows
    ${length}=    Get Length    ${rows}
    ${length}=    Evaluate    ${length}-1

    Remove From List    ${rows}    ${length}
    Remove From List    ${rows}    ${index}

    Log    ${headers}
    Log    ${rows}

    #add invoice headers
    FOR    ${headerElement}    IN    @{headers}
       Log    ${headerElement}
        @{headerItems}=    Split String    ${headerElement}    ;

        Add Invoice Header to DB    ${headerItems}
    END

    #add invoice rows
    FOR    ${rowElement}    IN    @{rows}
        Log    ${rowElement}
        @{rowItems}=    Split String    ${rowElement}    ;

        Add InvoiceRow to DB    ${rowItems}
    END

    Disconnect From Database
*** Tasks ***
Validate and update validation info to DB
    # Find all invoices with status -1 processing
    # Validations
    # Reference number

    #    *Invoice row amount vs invoice header amount
    Make Connection    ${dbname}
    ${invoices}=    Query    select invoice_number, reference_number, bank_account_number, total_amount from invoice_header where invoice_status_id = -1;

    FOR    ${element}    IN    @{invoices}
        Log    ${element}
        ${invoiceStatus}=    Set Variable    0    
        ${invoiceComment}=    Set Variable    All ok    
        
    #IBAN validation
        # Käytetään 'Check Iban' funkiota, jossa on suoritettu tilinumeron muunnokset ja laskutoimitukset.
        ${valid_iban}=    Check Iban    ${element}[2]
        # Jos validin IBAN numberon ehdot ei täyty, palautuu arvoksi 'False',
        # jolloin 'status' sarake saa arvon 2, ja 'comment' sarake arvon 'invalid iban'
        IF    ${valid_iban} == ${False}
            ${invoiceStatus}=    Set Variable    2
            ${invoiceComment}=    Set Variable    iban error
        END

    # Reference number validation
        ${valid_ref}=    Check Ref    ${element}[1]

        IF    ${valid_ref} == ${False}
            ${invoiceStatus}=    Set Variable    1
            ${invoiceComment}=    Set Variable    ref error
        END

        # Update the database
        @{params}=    Create List    ${invoiceStatus}    ${invoiceComment}    ${element}[0]
        ${updateStmt}=    Set Variable    update invoice_header set invoice_status_id = %s, comments = %s where invoice_number = %s;
        Execute Sql String    ${updateStmt}    parameters=${params}
    END


    Disconnect From Database