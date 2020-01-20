---
title: "What I need to learn for my Web Applications course."
date: 2020-01-18T17:25:58+01:00
draft: false
---

# Basic (HTML - 1)

## WWW
* Tim Berners-Lee, proposed WWW to CERN. Predecessor: ARPANET

## HTTP
* HyperTextTransportProtocol
* Stateless
* URI => Uniform Resource Identifier
* URL => Subset of URIs, Uniform Resource Locator. Describes primary access mechanism

### Request Methods

#### GET
* Retrieve Info
* Request: Request Header
* Response: Responser Header + Response Entity

#### POST
* Send + Retrieve Info
* Request Same + Request Entity
* Respinse: Same

### Status Codes
* 200 OK
* 301 Moved Permanently
* 302 Moved Temporarily
* 304 Not Modified (caching)
* 401 Unauthorized
* 403 Forbidden
* 404 Not Found
* 418 I'm a Teapot!
* 500 Internal Server Error

### MIME

* Multipurpose Internet Mail Extension

## Markup Languages

* Markup languages

* GML -> SGML -> HTML (1989) -> XML (1998) -> XHTML (1999) -> HTML5 (2008)

* HTML does Content, CSS presentation

### XHTML

### Structure

#### XML version & Encoding. XHTML  DOCTYPE

```xhtml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
```

XML is validated against the DTD file this points to.

XHTML is case sensitive

#### XHTML tag

```xhtml
<html xmlns="http://www.w3.org/1999/xhtml">
```

#### Markup Tags

Classification into three types:

* Stylistic Markup (font...) => use CSS instead
* Structal Markup (h1, div)
* Semantic Markup (title, strong)

Tag => `<h1>`
Element => `<h1>Hallo</h1>`

#### Syntax

* Everything must be well formed in XHTML or it explodes (so that's fun!)
* Every tag needs closing tag, even empty elements (`<br>` -> `<br/>`)
* Attribute names must be quoted
* Use "id" instead of "name"

#### Metadata

* SEO
* Keywords, Description, Expires ...

#### Character Encoding

* ASCII 128 Characters, 7-bit encoding
* ISO 8859-1 8-bit encoding, first 128 characters like ASCII
* Unicode Backwards compatible to ASCII, can fit over 1M chracters.
	* Most prelevant encoding is UTF-8.
	* [Difference between Unicode and UTF-8](https://stackoverflow.com/questions/643694/what-is-the-difference-between-utf-8-and-unicode)

#### Comments

`<!-- a fine html comment -->`

#### Tags
* h1 - h6
* p
* span => Structural/Semantic tag
* div
* ul
* ol
* a
* img src=""

##### Colours
* Hex, Name, RGB
* Alpha => Transperency

##### Class vs ID

ID used to identify a certain element, e.g. to access in JS. No spaces allowed
Class used to identify a common kind of elements, e.g. to modify all paragraph's look in CSS

### HTML (5)

Recommended to use lower-case for tags, but not case sensitive (usually).

#### Browser Wars

* First Major browser: Mosaic's Netscape in 1993
* Then MS's IE1 in 1995
* MS quickly increased its market share to 96% in 2002
* Safari/Webkit released in 2003
* Firefox forked off Netscape, 1.0 released in 2004
* Creation of WHATWG in 2004 by Mozilla, Apple and Opera (Working Group for drafting new standards for W3C to approve)
* IE quickly lost popularity vs Firefox.
* Google Chrome started out in 2008
* In 2010 Firefox catche up to IE and became the most popular browser
* In 2012 Chrome overtook FF

=> During this time HTML standard evolved quickly and became a bit messy

#### Evolution of HTML5

* HTML 1.0 -> 2.0 -> 3.{0,1,2} -> 4 -> XHTML 1 & 2 -> HTML5 (2014)

#### Differences to XHTML

##### Doctype

`<!DOCTYPE html>`

##### Sections

* Instead of just div and span loads of semantic dividers:
    * body
    * article (Some sort of complete/self-contained section)
    * section (generic section)
    * nav (navigation to other pages)
    * aside (content that is related to the content around it)
    * hgroup
    * header (beginning)
    * footer (footer)
    * address (contact info for nearest article/body)

#### New tags

* dl (a description list)
* figure (e.g. a picture)
    * figcaption
* video
* audio
* canvas
* svg

##### SVG

Vector graphics that do not lose quality if resized. Defined in XML format. Can be animated. Can even be inlined in HTML.

###### SVG Tags

* Shapes (e.g. Rectangle, Ellipse, Line, Polygon)
* Text
* It's possible to customize SVGs with CSS styling

# TCP/IP

## LAN VS WAN

* LAN (*L*ocal *A*rea *N*etwork) -> Your home network, e.g. for accessing servers in your own network
* WAN (*W*ide *A*area *N*etwork) -> Connection between LANs, many WANs build Internet. Used to connect to foreign servers

## Types of Addresses

* MAC -> Hardware address, assigned by manufacturer. Unique in network.
* IP Adress
	* Distributed in LAN by DHCP server
	* Distributed by RIPE NCC for global internet
	* v4 is currently being used, v6 in the process of being rolled out since v4 doesn't have enough adresses anymore.
	* Can point to one or multiple or no MAC addresses
        * No IP but MAC -> Device not reachable
        * One IP, one MAC -> Device is reachable in one network
        * Multiple IPs, one MAC -> Device is reachable in multiple networks
        * One IP, multiple MACs -> Multiple devices present as one, e.g. for load balancing, or as fall back
        * One IP, no MAC -> No device available

## Protocols

Protocols are encapsulated, so it's easy to swap out only a part of it (e.g. TCP vs UDP)

### IP

* "*I*nternet *P*rotocol"
* Contains IP Address of sender and receiver of the data package

### TCP
* "*T*ransmission *C*ontrol *P*rotocol"
* Contains the data that's sent
* 3 properties of TCP:
    * Connection Orientated
        * It's known who's the receiver
    * Packet-based
        * Data is split into packets, which may takes different routes to the destination, which may take a different amount of time
    * Reliable
        * All of the data arrives at the destination and arrives in the right order, so there are no duplicates
* Reliable due to getting a acknowledgement that the data has been transmitted sucessfully, but potentially slower due to that.

# Networks

### ISO/OSI

1. Bituebertragung Coax, Wireless
2. Sicherung IEEE 802.X, PPP
3. Vermittlung IP ARP/IP
4. Transport (TCP/UDP)
5. Sitzung RFC so und so
6. Darstellung FTP/SMTP
7. Anwendung (File Transfer, EMail)

* Layer 1&2 implemented via network adapter.
	* Different connectors on adapters:
		* RJ45: the most common one. 8 Pins w/ twisted pairs of cables inside. In star topology:
			* Advantanges:
				* The network doesn't crash if one system crashes
				* Easy to extend
				* Easy to diagnose errors
			* Disadvantages:
				* Switches are critical components
				* Lots of effort to run cables
		* Previously BNC was used in bus topology:
			* Advantages:
				* Network doesn't crash if one system crashes
				* Easy to extend
			* Disadvantages:
				* Databus is critical component
				* All devices share one databus
	* Hubs operate on layer 1 too, since they duplicate packets
	* Switches operate on layer 2, redirect packets to their destination in a network

* Routing implements Layer 3
	* Sets the path a data packet takes

# CSS, CGI

# JavaScript

# Cookies, dynamic HTML, DOM, events, Web 2.0, AJAX

# Network Basics

# Design guidelines

# Password Hashing

* Schutzmaßnahme vor Diebstahl von Passwörtern

* Algorithmen sind One-Way-Funktionen (gehashtes Passwort kann nicht ungehasht werden)

* Konvertieren beliebig lange Zeichenketten in Hashwert fixer Länge

* Kleine Änderungen der Zeichenkette -> große Änderungen des Hashwertes

## Ablauf

* Beim Registrieren benutztes Passwort wird gehasht und so gespeichert

* Beim Login wird die Eingabe gehasht und mit dem gespeicherten Hashwert verglichen


## Angriffe

### Dictionary Attack

* Liste mit vorgefertigten Passwörtern zum Angriff nutzen

* Funktioniert, wenn Passwort sinnig ist, statt zufällige Wortkombis (meistens der Fall)

### Brute Force

* Alle möglichen Zeichenketten ausprobieren (aa -> ab -> ba -> bb... usw.)

* Sehr zeitaufwendig, insbesondere ab größerer Länge

### Lookup Tables

* Liste mit gespeicherten Hashwerten und zugehörigen Passwörtern

* Nutzt man, um Originalpasswort aus Hashwert zu beziehen

### Reverse Lookup Tables

* Lookup Tables, welche Usernames auf Basis von Passwörtern suchen können

### Rainbow Tables

* Spezielle Version von Lookup Tables

* Platzsparender, brauchen aber mehr Rechenresourcen (speichern Passwörter und Hashes als Ketten)


## Salt

* Vom Benutzer eingegebenes Kennwort wird vor dem Hashen mit einem individuellen Zahlenwert versehen

* Mehr Varietät beim Hashwert -> sicherer

### Fehler beim Salzen

* Salt Reuse

* Short Salt


## Hash Collision

* mehrere Klarzeichenketten haben gleichen Hashwert (-> hash algortihm broken, like md5)


### Sicherheitsmaßnahmen

* CSPRNG für Salt-Erzeugung

* Nur individuellen Salt verwenden (Salts müssen nicht geheim sein)

* Salt ungehasht mit Hashwert bei Passworterstellung abspeichern

* Beim Einloggen Salt und Nutzereingabe zusammenfügen und mit Hashwert vergleichen

* Hashwerte auf dem Server berechnen, da sicherer als im Browser

* Nutzer darf nicht die Möglichkeit haben, sich direkt mit Hashwerten einzuloggen

* __Je schneller eine Hashfunktion, desto schlechter__

* Beispiel Hashfunktionen
	* MD5, SHA1 (schnell und schlecht)
	* PBKDF2 (langsam und sicher)
		* Mehrmals Salten und Hashen (Key Stretching)
		* WPA2 nutzt dies z.B.
		* schnell berechenbar mit GPUs
	* Argon2
		* Absichtlich hohe RAM-Belegung

### Was bringen die einzelnen Verfahren?

* Hashen
	* Passwort kann bei Serverhack nicht ausgelesen werden
	* Rainbow Tables umgehen Hashes

* Salten
	* Rainbow Tables nicht nutzbar
	* Brute Force, Dictionary Attack oder GPU zur Berechnung nutzen

* Salten und aktuelle/sichere Hashfuntkionen
	* GPU zu langsam/Berechnung unmöglich
	* Brute Force mit CPU -> ebenfalls viel zu langsam
	* __-> ERFOLGSLOS__

# HTTPS

HTTPS = HTTP + TLS. Secures data.

## Objectives
* Integrity (Certificate of the website)
* Authenticy
* Confidentially

## Certificates

Either self-signed (so not trusted by a standard webbrowser) or signed via a CA.
CA Signed certificates can be extended-valdidated, meaning it also displays a name
on the certificate for more trust.

## Server Hello

1. client hello (send server client's SSL and TLS version and the preferred cyphers)
2. server hello (send chosen cypher, session ID and certificate).
3. client verifies certificate
4. client creates symmetric session key
5. client sends encrypted session key (encrypted with server public key)
6. server decrypts session key with its private keys
7. server acknowledges sucessful key exchange

## SSL
*S*ecure *S*ocket *L*ayer, an encryption protocol. Overtaken by TLS

## TLS
*T*ransport *L*ayer *S*ecurity sucessor of SSL.

## HTTPS in the OSI Model

If using HTTPS TLS is added to the transport layer

## History (ugh)

SSL 1.0 and 2.0 (1994), 3.0 (1998). TLS in 1999 and TLS 1.3 in 2018

# AJAX and XML (fun!)

AJAX (*A*synchronos *J*avascript *A*nd *X*ML) can be used to dynamically change a site, without reloading it, thus making the
website seem more responsive. In theory AJAX can also send YML or JSON.

XML, the e*X*tensible *M*arkup *L*anguage. A XML file can be validated against a DTD (Structure Definition),
or a XML Scheme . XML describes the syntax, XSL describes the semantics.

Example:

```
<?xml version="1.0" standalone="no" encoding="UTF-8"?>
<BUCH>
<TITEL>Faust</TITEL>
<AUTOR>Johann Wolfgang von Goethe</AUTOR>
</BUCH>
```

Tags are case sensitive! Must be well formed => all elements must be opened subsequently closed, nested without overlap and terminated empty element.

## HTML vs XML:

`<img src="pic.png"> vs <img src="pic.png"/>`

## Well-formed vs Valid XML

Well-formed XML doesn't need a DTD but is syntax checked. Valid XML requires a
DTD to be validated. The DTD defined the document structure with a list of legal
elements and attributes.


## Namespaces

It's possible to define namespaces in the XML file so that one can use different DTD files in one XML file.

E.g.

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<html xmlns="http://www.w3.org/1999/xhtml">
	xhtml elements
	<math xmlns="http://www.w3.org/1998/Math/MathML">
		Math elements
	</math>
	xhtml elements
</html>
```

Or it's even possible to set `xmlns:namespace` and then adding `<tagname:namespace>` to only use a DTD file for one tag.

# Videocodecs

First videocodecs developed by MPEG and ITU with JPEG compression of individual frames of movie.

Different codecs:
	* AVI
	* MPEG
	* VOB (DVD)
	* ASF
	* OGG
	* MKV

_Goal of a video codec: Compressing video, either in a lossless or lossy manner_

Lossy:
	* Removing information that's deemed unimportant (i.e. not perceivable by humans)
Lossless:
	* Only removing redundant information, e.g. if two frames are the same

Videocompression techniques:
	If lossless, then the pictures are compressed first, e.g. by setting one, average colour per 4X4 block of pixels.
	Compression via I,P and B frames:
		* I (Intra): A complete frame
		* P (Predicted): Changes (delta) between I frames. Weak compression. Uses data from previous frame for delta and compresses that
		* B (Bidirectional): Changes (delta) between a I or P frame. Strong compression. Uses data from previous and forward frames for compression.
