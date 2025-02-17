*** Settings ***
Library    OperatingSystem
Library    String
Library    Collections
Library    DatabaseLibrary

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

    #TODO:
    #Päivämäärät
    #Summatiedot
    ${insertStmt}=    Set Variable    insert into invoice_header (invoice_number, company_name, company_code, reference_number, invoice_date, due_date, bank_account_number, amount_exclude_vat, vat, total_amount, invoice_status_id, comments) values ('${items}[0]', '${items}[1]', '${items}[5]', '${items}[2]', '2000-01-01', '2000-01-01', '${items}[6]', 0, 0, 0, -1, 'Processing');
    
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

    FOR    ${headerElement}    IN    @{headers}
        Log    ${headerElement}
        @{headerItems}=    Split String    ${headerElement}    ;

        Add Invoice Header to DB    ${headerItems}

    END