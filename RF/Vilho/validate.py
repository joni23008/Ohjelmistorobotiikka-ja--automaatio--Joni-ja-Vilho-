import re

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
