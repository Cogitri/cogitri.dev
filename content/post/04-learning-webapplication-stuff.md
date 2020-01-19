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
* 428 I'm a Teapot!
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

### ISO/OSI

1. Bituebertragung Coax, Wireless
2. Sicherung IEEE 802.X, PPP
3. Vermittlung IP ARP/IP
4. Transport (TCP/UDP)
5. Sitzung RFC so und so
6. Darstellung FTP/SMTP
7. Anwendung (File Transfer, EMail)

# TCP/IP

## LAN VS WAN

* LAN (*L*ocal *A*rea *N*etwork) -> Your home network
* WAN (*W*ide *A*area *N*etwork) -> Connection between LANs, many WANs build Internet

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


# CSS

## What is CSS?

* **C**ascading **S**tyle **S**heets

* Styles define how to display HTML elements

* Introduced in HTML 4.0


## Why CSS?

* Solved the problem of HTML's scientific background (design and presentation were not in mind)

* Easier management and maintenance

* Cleaned-up HTML code

* Unified site design


## Syntax and Standards

* MIME type (according to W3C) "text/css" (MIME type tells the user client which parser to use)

* Syntax:

	```c
	selector
	{
		property:value;
	}
	```


## Types of Style Sheets

* Author Style Sheets (highest priority)
	* Made by the web page's author
	* Makes up the biggest part
	
* User Style Sheets (mediocre priority)
	* Set by the web page's user (user's own CSS files)
	* Allows for greater customization/user friendliness
	
* User Agent Sytle Sheets (lowest priority)
	* Automatic implementation by the browser
	* Helps with compatibility (```<em>``` tag is displayed as italicized in XHTML e.g.)
	
* General priority rules:
	* "Come first, serve first" for external files (the higher their placing, the higher their priority)
	* Gather all declarations for one element
	* Sort by file origin
	* Sort by definition rules of files
	* Elements follow inheritance rules
		
* **!important tag**
	* Overwrites priority
	* Syntax example:
	
		```c 
		body
		{
			color:red !important;
		}
		```
		
		
## HTML integration

* Different ways of integration
	* Inline (lower priority than internal/external)
	* Internal
	* External (seperate file)
	
* Inline 

	```c
	<p style="color:dodgerblue;font-family:"Comic Sans";">...</p>
	```

* Internal:

	```c
	<style type="text/css">
		p.special { color: rgb(230, 100, 180); }
	</style>
	```

* External

	```c
	<head>
	<link rel="stylesheet" href="css/styles.css"> <--! optional media="print" mit einfügen -->
	...
	<link rel="stylesheet" media="print" href="css/print.css">
	</head>
	```
	
## Tagging

#### Identifiers (IDs)

* Syntax
	* CSS syntax:
	
		```c
		#idname
		{
			...
		}
		```
	
	* HTML syntax:
	
		```c
		<selector id="idname">....</selector>
		```
		
* Used for unique elements (one specific paragraph e.g.)
	
#### Classes
	
* Syntax
	* CSS syntax: 
			
		```c
		selector.classname /* selector is optional for classes */
		{
			...
		}
		```
			
	* HTML syntax:
		
		```c
		<selector class="classname">...</selector>
		```
		
* Used to style repeatingly used elements (e.g. menues, special paragraphs)
		
### Special Tagging Rules

#### Link Tagging

```c
a:status
{
	...
}
```

* "Pseudo Class"

* Possible statuses
	* link (default (no action))
	* visited (page was vistited once at least (no action))
	* active (on-click)
	* hover
	
### Spans

* Inline HTML tag to add some CSS

```c
<p> This is text, <span style="color:dodgerblue;font-family:"Comic Sans";">though this is formatted.</span></p>
```

## Positioning

* Ordering  
	- Lower number -> more outer placing

1. Margin
	* Outer space of an element's border relative to its parent
	
2. Border

3. Padding
	* Inner space of an element relative to its border
	
#### CSS attributes

* Static
	* Default (flow of the page)
	
* Fixed
	* Relative to browser window (won't move, not even on scroll)
	
* Relative
	* Relative to its normal position
	
* Absolute
	* Relative to first parents that has no static tag (relative to browser window if no such element is found)

* Example
	
	```c
	#idname
	{
		position: absolute;
		...
	}
	```

* z-index
	* Layering of different elements
	
		```c
		selector
		{
			z-index: -1;
			...
		}
		```

* float
	* Elements "float" to the left or to the right
	
		```c
		selector
		{
			float:right;
		}
		```
		
	* Can be "cleared for other elements
	
		```c
		other-selector
		{
			clear:right; /* left, right, and both are usable values */
		}
		```
	
## Units

* Absolute
	* pt = point
	* in, cm, mm

* Relative
	* px = pixel (relative to monitor res)
	* % = percentage (relative to fontsize or box)
