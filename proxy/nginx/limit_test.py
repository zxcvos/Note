import urllib.request
response = urllib.request.urlopen('https://www.example.com/')
print(response.read().decode('utf-8'))
