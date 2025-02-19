*** Settings ***
Library    DatabaseLibrary
Library    OperatingSystem
Library    String
Library    Collections
Library    Process
Library    DateTime

*** Variables ***
# polku csv
${PATH}    CSV\\
# database
${dbname}    rpa
${dbuser}    robotuser
${dbpass}    jonijavilho
${dbhost}    localhost    
${dbport}    3306

*** Keywords ***
Make connection
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}
Add Invoice Header To DB
    [Arguments]    ${items}
    Make connection

    # Nää on kovakoodattu ny (-1, Processing)
    # Status tiedot (invoice_status_id, comments)
    # Se on ok, koska kun ne ladataan tietokantaan ensin ne on aina prosessoitava sen jälkeen.
    
    # Päivämäärät (invoice_date, due_date) [4, 5]
    ${invoiceDate}=    Convert Date    ${items}[4]    date_format=%d.%m.%Y    result_format=%Y-%m-%d
    ${dueDate}=    Convert Date    ${items}[5]    date_format=%d.%m.%Y    result_format=%Y-%m-%d

    ${insertStatement}=    Set Variable    insert into invoice_header (invoice_number, company_name, company_code, reference_number, invoice_date, due_date, bank_account_number, amount_exclude_vat, vat, total_amount, invoice_status_id, comments) values ('${items}[0]', '${items}[1]', '${items}[2]', '${items}[3]', '${invoiceDate}', '${dueDate}', '${items}[6]', '${items}[7]', '${items}[8]', '${items}[9]', -1, 'Processing');
    Log    ${insertStatement}
    Execute Sql String    ${insertStatement}

    Disconnect From Database
Add Invoice Row To DB
    [Arguments]    ${items}
    Make connection
    
    ${insertStatement}=    Set Variable    insert into invoice_row (invoice_number,rownumber,description,quantity,unit,unit_price,vat_percent,vat,total) values ('${items}[0]', '${items}[1]', '${items}[2]', '${items}[3]', '${items}[4]', '${items}[5]', '${items}[6]', '${items}[7]', '${items}[8]');
    Log    ${insertStatement}
    Execute Sql String    ${insertStatement}

    Disconnect From Database
*** Tasks ***
read csv to list
    # luetaaan csv tiedosto yhteen merkkijonoon
    ${outputHeader}    Get File    ${PATH}InvoiceHeaderData.csv
    ${outputRow}    Get File    ${PATH}InvoiceRowData.csv
    Log    ${outputHeader}
    Log    ${outputRow}
    # merkkijonosta jokainen rivi omana elementtinään listaan, erotetaan rivinvaihdolla (\n)
    @{headers}    Split String    ${outputHeader}    \n
    @{rows}    Split String    ${outputRow}    \n
    # tulokset tässä kohtaa
    Log    ${headers}
    Log    ${rows}
    # haetaan otsikko listan pituus, poistetaan viimenen ('' = tyhjä) ja poistetaan ensimmäinen (csv otsikot)
    ${length}    Get Length    ${headers}
    ${length}    Evaluate    ${length}-1
    ${index}    Convert To Integer    0
    Remove From List    ${headers}    ${length}
    Remove From List    ${headers}    ${index}
    # haetaan rivi listan pituus, poistetaan viimenen ('' = tyhjä) ja poistetaan ensimmäinen (csv otsikot)
    ${length}    Get Length    ${rows}
    ${length}    Evaluate    ${length}-1
    ${index}    Convert To Integer    0
    Remove From List    ${rows}    ${length}
    Remove From List    ${rows}    ${index}
    # tulokset tässä kohtaa
    Log    ${headers}
    Log    ${rows}
    # Otsikot lisätään tietokantaan otsikko kerrallaan
    FOR    ${headerElement}    IN    @{headers}
        Log    ${headerElement}
        @{headerItems}=    Split String    ${headerElement}    ;
        Add Invoice Header To DB    ${headerItems}
    END
    # Rivit lisätään tietokantaan rivi kerrallaan
    FOR    ${rowElement}    IN    @{rows}
        Log    ${rowElement}
        @{rowItems}=    Split String    ${rowElement}    ;
        Add Invoice Row To DB    ${rowItems}
    END


*** Tasks ***
Validate and update validation info to DB
    # Etsi kaikki invoicet joiden status id on -1 eli processing
    # Validoi:
    #     - reference number
    #     - IBAN
    #     - invoice row summa vs invoice header summa
    Make connection

    ${invoices}=    Query    select invoice_number, reference_number, bank_account_number, total_amount from invoice_header where invoice_status_id = -1;

    FOR    ${invoice}    IN    @{invoices}
        Log    ${invoice}
        ${invoiceStatus}=    Set Variable    0
        ${invoiceComment}=    Set Variable    All ok
        
        # Validoinnit
        
        # päivitä header taulu
        @{params}=    Create List    ${invoiceStatus}    ${invoiceComment}    ${invoice}[0]
        ${updateStatement}=    Set Variable    update invoice_header set invoice_status_id = %s, comments = %s where invoice_number = %s;
        Execute Sql String    ${updateStatement}    parameters=${params}
    END

    Disconnect From Database


# select data from database
    # Make connection
    # @{invoicestatusList}=    Query    select * from invoice_status;

    # FOR    ${element}    IN    @{invoicestatusList}
    #     Log    ${element}
    #     Log    ${element}[0]
    #     Log    ${element}[1]
        
    # END

    # Disconnect From Database

# insert data to database
# ei onnistu koska robotilla ei ole oikeuksia
# grant insert on invoicestatus to robotrole;
# jos oikeutta ei tarvita
# revoke insert on invoicestatus from robotrole;

    # Make connection
    # ${insert}=    Set Variable    insert into invoice_status (id, name) values (100, 'testi')
    # Log    ${insert}
    # Execute Sql String    ${insert}

    # Disconnect From Database