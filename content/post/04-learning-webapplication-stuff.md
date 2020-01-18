---
title: "What I need to learn for my Web Applications course."
date: 2020-01-18T17:25:58+01:00
draft: false
---

# Historie

# WWW
* Tim Berners-Lee, proposed WWW to CERN. Vorgaenger: ARPANET

# HTTP
* HyperTextTransportProtocol
* Stateless
* URI => Uniform Resource Identifier
* URL => Subset of URIs, Uniform Resource Locator. Describes primary access mechanism

## Request Methods

### GET
* Retrieve Info
* Request: Request Header
* Response: Responser Header + Response Entity

## POST
* Send + Retrieve Info
* Request Same + Request Entity
* Respinse: Same

## Status Codes
* 200 OK
* 301 Moved Permanently
* 302 Moved Temporarily
* 304 Not Modified (caching)
* 401 Unauthorized
* 403 Forbidden
* 404 Not Found
* 428 I'm a Teapot!
* 500 Internal Server Error

## MIME

* Multipurpose Internet Mail Extension

# HTML, XHTML

* Markup languages

* GML -> SGML -> HTML (1989) -> XML (1998) -> XHTML (1999) -> HTML5 (2008)

* HTML does Content, CSS presentation

# XHTML

## Structure

### XML version & Encoding. XHTML  DOCTYPE

```xhtml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
```

XML is validated against the DTD file this points to.

XHTML is case sensitive

### XHTML tag

```xhtml
<html xmlns="http://www.w3.org/1999/xhtml">
```

## Markup Tags

Classification into three types:

* Stylistic Markup (font...) => use CSS instead
* Structal Markup (h1, div)
* Semantic Markup (title, strong)

Tag => `<h1>`
Element => `<h1>Hallo</h1>`

## Syntax

* Everything must be well formed in XHTML or it explodes (so that's fun!)
* Every tag needs closing tag, even empty elements (`<br>` -> `<br/>`)
* Attribute names must be quoted
* Use "id" instead of "name"

## Metadata

* SEO
* Keywords, Description, Expires ...


## Character Encoding

* ASCII 128 Characters, 7-bit encoding
* ISO 8859-1 8-bit encoding, first 128 characters like ASCII
* Unicode Backwards compatible to ASCII, can fit over 1M chracters.
	* Most prelevant encoding is UTF-8.
	* [Difference between Unicode and UTF-8](https://stackoverflow.com/questions/643694/what-is-the-difference-between-utf-8-and-unicode)

## Comments

`<!-- a fine html comment -->`

## Tags
* h1 - h6
* p
* span => Structural/Semantic tag
* div
* ul
* ol
* a
* img src=""

### Farben
* Hex, Name, RGB
* Alpha => Transperency


## Class vs ID

ID used to identify a certain element, e.g. to access in JS. No spaces allowed
Class used to identify a common kind of elements, e.g. to modify all paragraph's look in CSS

## HTML (5)

Recommended to use lower-case for tags, but not case sensitive (usually).

## ISO/OSI

1. Bituebertragung Coax, Wireless
2. Sicherung IEEE 802.X, PPP
3. Vermittlung IP ARP/IP
4. Transport (TCP/UDP)
5. Sitzung RFC so und so
6. Darstellung FTP/SMTP
7. Anwendung (File Transfer, EMail)

# HTML markup tags

# CSS, CGI

# JavaScript

# Cookies, dynamic HTML, DOM, events, Web 2.0, AJAX

# Network Basics

# Design guidelines
