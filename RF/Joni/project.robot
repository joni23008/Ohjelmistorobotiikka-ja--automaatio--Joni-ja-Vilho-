*** Settings ***
Library    DatabaseLibrary
Library    OperatingSystem
Library    String
Library    Collections
Library    Process
Library    DateTime
Library    validate.py
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
Make Connection
    Connect To Database    pymysql    ${dbname}    ${dbuser}    ${dbpass}    ${dbhost}    ${dbport}
Add Invoice Header To DB
    [Arguments]    ${items}
    Make Connection
    # Nää on kovakoodattu ny (-1, Processing)
    # Status tiedot (invoice_status_id, comments)
    # Se on ok, koska kun ne ladataan tietokantaan ensin ne on aina prosessoitava sen jälkeen.
    # 
    # Päivämäärät (invoice_date, due_date) [4, 5]
    ${invoiceDate}=    Convert Date    ${items}[4]    date_format=%d.%m.%Y    result_format=%Y-%m-%d
    ${dueDate}=    Convert Date    ${items}[5]    date_format=%d.%m.%Y    result_format=%Y-%m-%d
    # syötetään otsikko-tiedot tietokantaan
    ${insertStatement}=    Set Variable    insert into invoice_header (invoice_number, company_name, company_code, reference_number, invoice_date, due_date, bank_account_number, amount_exclude_vat, vat, total_amount, invoice_status_id, comments) values ('${items}[0]', '${items}[1]', '${items}[2]', '${items}[3]', '${invoiceDate}', '${dueDate}', '${items}[6]', '${items}[7]', '${items}[8]', '${items}[9]', -1, 'Processing');
    Log    ${insertStatement}
    Execute Sql String    ${insertStatement}
    # 
    Disconnect From Database
Add Invoice Row To DB
    [Arguments]    ${items}
    Make Connection
    # syötetään rivi-tiedot tietokantaan
    ${insertStatement}=    Set Variable    insert into invoice_row (invoice_number,rownumber,description,quantity,unit,unit_price,vat_percent,vat,total) values ('${items}[0]', '${items}[1]', '${items}[2]', '${items}[3]', '${items}[4]', '${items}[5]', '${items}[6]', '${items}[7]', '${items}[8]');
    Log    ${insertStatement}
    Execute Sql String    ${insertStatement}
    # 
    Disconnect From Database
Check Amount From Invoice
    # tuodaan argumentteina otsikon ja rivien summat
    [Arguments]    ${headerAmount}    ${rowsAmount}
    # defaulttina status on false eli väärin
    ${status}=    Set Variable    ${False}
    # muuttujien sisältö muutetaan numeroiksi
    ${headerAmount}=    Convert To Number    ${headerAmount}
    ${rowsAmount}=    Convert To Number    ${rowsAmount}
    # virhe toleranssi
    ${diff}=    Convert To Number    0.01
    # Viedään python koodille numeraaliseksi muutettu otsikko summa,rivisumma ja virhetoleranssi > validate.py
    ${status}=    Is Equal    ${headerAmount}    ${rowsAmount}    ${diff}
    # palautetaan status (false = väärin, true = oikein)
    RETURN    ${status}
Convert Query Result To Decimal List
    # tuodaan argumenttina lista rivien summia, ne on jossain 'decimal' muodossa tai tuplessa, ne pitäs saada normaaliin numeraaliseen listaan 
    [Arguments]    ${query_result}
    # luodaan tyhjä lista
    ${decimal_list}    Create List
    # loopissa muutetaan query_result numeraaliseksi ja työnnetään se juuri luodulle listalle
    FOR    ${row}    IN    @{query_result}
        ${value}    Convert To Number    ${row}[0]
        Append To List    ${decimal_list}    ${value}
    END
    # palautetaan korrektissa muodossa oleva lista jatkokäsittelyä varten
    RETURN    ${decimal_list}
*** Tasks ***
Read CSV To List
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
Validate And Update Validation Info To DB
    Make Connection
    # Query jolla etsitään kaikki invoicet joiden status id on -1 eli processing
    ${invoices}=    Query    select invoice_number, total_amount from invoice_header where invoice_status_id = -1;
    # Status id:t ja kommentit, nää vois jaksais hakea tietokannasta joskus
    @{invoiceStatus}=    Create List    -1    0    1    2    3
    @{invoiceComment}=    Create List    Processing    All ok    ref error    iban error    amount error
    # Query jolla päivitetään laskun status id ja kommentti
    ${updateStatement}=    Set Variable    update invoice_header set invoice_status_id = %s, comments = %s where invoice_number = %s;

    # Silmukassa käydään läpi jokainen header otsikko jossa status id oli -1
    FOR    ${invoice}    IN    @{invoices}

        # TESTAAMISTA VARTEN:::
        ${testi}=    Set Variable    666
        ${testi}=    Convert To Integer    ${testi}
        Log    ${invoice}

        # Hae rullaavan laskun laskunumeron mukaan kaikki rivit ja niistä summat tietokannasta
        ${invoiceRowsAmounts}=    Query    select total from invoice_row where invoice_number = '${invoice}[0]';

        # Parametri-listat eri skenaarioille:
        # All ok = Kaikki OK tällä laskulla!
        @{ok}=    Create List    ${invoiceStatus}[1]    ${invoiceComment}[1]    ${invoice}[0]
        # amount error = Summa on väärin tällä laskulla!
        @{summaVäärä}=    Create List    ${invoiceStatus}[3]    ${invoiceComment}[3]    ${invoice}[0]


        # käytetään keywordia: Convert Query Result To Decimal List, siellä muutetaan querysta saatu lista numeraaliseksi
        ${totals}    Convert Query Result To Decimal List    ${invoiceRowsAmounts}
        # TÄHÄN LISÄÄ...............................................

        # summataan listan kaikki elementit yhteen
        ${rowsTotalResult}    Evaluate    sum(${totals})
        # TÄHÄN LISÄÄ...............................................

        # tarkistetaan summa, argumenteiksi annetaan tämänhetkisen laskun total ja juuri summattu rivien tulos
        # TESTAAMISTA VARTEN:::
        # ${totalStatus}=    Check Amount From Invoice    ${testi}    ${rowsTotalResult}
        ${totalStatus}=    Check Amount From Invoice    ${invoice}[1]    ${rowsTotalResult}
        # TÄHÄN LISÄÄ...............................................



        IF    ${totalStatus}
            Log    Laskulla | ${invoice}[0] | summat täsmäävät, header= ${invoice}[1] VS rows= ${rowsTotalResult} | testi= ${testi}
            # Päivitetään header tauluun tälle laskulle, tämän mukaan status id ja kommentti
            Execute Sql String    ${updateStatement}    parameters=${ok}
        ELSE
            Log    Laskulla | ${invoice}[0] | summat EI täsmää, header= ${invoice}[1] VS rows= ${rowsTotalResult} | testi= ${testi}
            # Päivitetään header tauluun tälle laskulle, tämän mukaan status id ja kommentti
            Execute Sql String    ${updateStatement}    parameters=${summaVäärä}
        END


        # MUITA VALIDOINTEJA
        

    END
    Disconnect From Database
    
