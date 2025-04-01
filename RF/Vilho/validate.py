import re

    # Luodaan tilinumeron tarkastusta varten funktio
def check_Iban(Iban: str) -> bool:
    
    # Poistetaan IBAN numerosta välilyönnit ja muunnetaan kirjaimet isoiksi
    Iban = Iban.replace(" ", "").upper()

    # Suomalainen IBAN numero on tasan 18 merkin mittainen ja alkaa kirjaimilla 'FI'
    if not re.match(r"^FI\d{16}$", Iban):
        return False

    # Siirretään IBAN numeron alkuosa loppupäähän (esim. 'FI2112..' -> '..785FI21')
    rearrangedIban = Iban[4:] + Iban[:4]

    # Muunnetaan kirjaimet kokonaisluvuiksi (A=10, B=11...)
    numericIban = ''.join(str(ord(char) - 55) if char.isalpha() else char for char in rearrangedIban)

    # IBAN / 97 = 1
    return int(numericIban) % 97 == 1

    # Testi
if __name__ == "__main__":
    test_Iban = "FI2112345600000785"
    print(check_Iban(test_Iban))  # True (jos IBAN on muodostettu oikein)



    # Luodaan viitenumeron tarkastusta varten funktio
def check_Ref(Ref: str) -> bool:


    # Varmistetaan, että viitenumerossa on ainoastaan lukuarvoja
    if not Ref.isdigit():
        return False

    invoice_Num = Ref[:-1]  # Laskun numero (viitenumerosta vähennetty viimeinen luku)
    check_Digit_Given = int(Ref[-1])  # Otetaan viitenumeron viimeinen luku (check_Digit_Given)

    multiply = [7, 3, 1]  # Luodaan lista 7,3,1 menetelmälle


    # Luodaan laskutoimitus viitenumeron viimeiselle luvulle
    weighted_Sum = sum(int(digit) * multiply[i % 3] for i, digit in enumerate(reversed(invoice_Num)))

    next_Of_10 = (weighted_Sum + 9) // 10 * 10  # Pyöristetään lähimpään kymmeneen
    check_Digit_Computed = next_Of_10 - weighted_Sum  # Erotus = Viitenumeron viimeinen luku

    return check_Digit_Computed == check_Digit_Given  # Verrataan ohjelman laskettua viitenumeroa, ja valmiiksi annettua viitenumeroa

    # Testi
test_Ref = "1431432"

print(check_Ref(test_Ref))
