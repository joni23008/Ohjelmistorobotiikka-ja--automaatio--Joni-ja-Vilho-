*** Settings ***
Library    DatabaseLibrary
Library    OperatingSystem
Library    String
Library    Collections

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

*** Tasks ***
read csv to list
    Make connection
    ${outputHeader}    Get File    ${PATH}InvoiceHeaderData.csv
    ${outputRow}    Get File    ${PATH}InvoiceRowData.csv
    Log    ${outputHeader}
    Log    ${outputRow}
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