#!/usr/bin/env python3

# Permet de récupérer le contenu d'une page web (journal) et d'afficher uniquement le contenu pertinent de l'article (titre, corps de texte).
# Script python utilisable avec Newsboat (cf ~/.config/newsboat/config).

from newspaper import Article
import sys

url = sys.argv[1]
a = Article(url)
a.download()
a.parse()

c = a.title.count("",1)

print(a.title)
print("="*c)
print("")
print(a.text)

# Idée originale : https://hund.tty1.se/2020/07/29/an-introduction-to-the-web-feed-client-newsboat.html
