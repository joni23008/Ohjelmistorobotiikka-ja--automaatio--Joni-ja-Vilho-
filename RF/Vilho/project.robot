*** Settings ***
Library    OperatingSystem
Library    String
Library    Collections
Library    DatabaseLibrary
Library    DateTime
Resource    ../Joni/project.robot

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

    ${insertStmt}=    Set Variable    insert into invoice_header (invoice_number, company_name, company_code, reference_number, invoice_date, due_date, bank_account_number, amount_exclude_vat, vat, total_amount, invoice_status_id, comments) values ('${items}[0]', '${items}[1]', '${items}[5]', '${items}[2]', '${invoice_date}', '${due_date}', '${items}[6]', ${items}[7], ${items}[8], ${items}[9], -1, 'Processing');
    
    Log    ${insertStmt}
    Execute Sql String    ${insertStmt}

    Disconnect From Database

*** Keywords ***
Add InvoiceRow to DB
    [Arguments]    ${items}
    Make Connection    ${dbname}

    ${insertStmt}=    Set Variable    insert into invoice_row (invoice_number, rownumber, description, quantity, unit, unit_price, vat_percent, vat, total) values ('${items}[0]', '${items}[1]', '${items}[2]', '${items}[3]', '${items}[4]', '${items}[5]', '${items}[6]', '${items}[7]', '${items}[8]');
    Log    ${insertStmt}
    Execute Sql String    ${insertStmt}

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