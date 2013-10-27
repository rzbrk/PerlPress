-- MySQL dump 10.14  Distrib 5.5.32-MariaDB, for Linux (x86_64)
-- ------------------------------------------------------
-- Server version	5.5.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Create database perlpress
--

DROP DATABASE IF EXISTS perlpress;
CREATE DATABASE perlpress;
USE perlpress;

--
-- Table structure for table `art_cat`
--

DROP TABLE IF EXISTS `art_cat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `art_cat` (
  `art_id` int(11) unsigned NOT NULL,
  `cat_id` int(11) unsigned NOT NULL,
  UNIQUE KEY `constr1` (`art_id`,`cat_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `art_cat`
--

/*!40000 ALTER TABLE `art_cat` DISABLE KEYS */;
INSERT INTO `art_cat` VALUES (1,1);
INSERT INTO `art_cat` VALUES (2,2);
INSERT INTO `art_cat` VALUES (2,3);
INSERT INTO `art_cat` VALUES (3,2);
INSERT INTO `art_cat` VALUES (4,3);
/*!40000 ALTER TABLE `art_cat` ENABLE KEYS */;

--
-- Table structure for table `art_tag`
--

DROP TABLE IF EXISTS `art_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `art_tag` (
  `art_id` int(11) unsigned NOT NULL,
  `tag_id` int(11) unsigned NOT NULL,
  UNIQUE KEY `constr1` (`art_id`,`tag_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `art_tag`
--

/*!40000 ALTER TABLE `art_tag` DISABLE KEYS */;
INSERT INTO `art_tag` VALUES (1,1);
INSERT INTO `art_tag` VALUES (2,2);
INSERT INTO `art_tag` VALUES (2,3);
INSERT INTO `art_tag` VALUES (2,4);
INSERT INTO `art_tag` VALUES (3,2);
INSERT INTO `art_tag` VALUES (3,4);
INSERT INTO `art_tag` VALUES (4,4);
INSERT INTO `art_tag` VALUES (4,5);
INSERT INTO `art_tag` VALUES (4,6);
/*!40000 ALTER TABLE `art_tag` ENABLE KEYS */;

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `articles` (
  `art_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(80) COLLATE utf8_bin NOT NULL DEFAULT '',
  `subtitle` varchar(80) COLLATE utf8_bin NOT NULL DEFAULT '',
  `alias` text COLLATE utf8_bin NOT NULL,
  `link` text COLLATE utf8_bin NOT NULL,
  `author` varchar(80) COLLATE utf8_bin NOT NULL DEFAULT 'unknown',
  `intr_text` mediumtext COLLATE utf8_bin NOT NULL,
  `full_text` mediumtext COLLATE utf8_bin NOT NULL,
  `created` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `modified` datetime NOT NULL DEFAULT '2000-01-01 00:00:00',
  `type` enum('blog','page','nav') COLLATE utf8_bin NOT NULL DEFAULT 'blog',
  `status` enum('draft','published','unpublished') COLLATE utf8_bin NOT NULL DEFAULT 'draft',
  `icon` text COLLATE utf8_bin NOT NULL,
  `notes` mediumtext COLLATE utf8_bin NOT NULL,
  `visits` int(11) NOT NULL DEFAULT '0',
  `oldurl` text COLLATE utf8_bin,
  `featured` enum('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
  PRIMARY KEY (`art_id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `articles`
--

/*!40000 ALTER TABLE `articles` DISABLE KEYS */;
INSERT INTO `articles` VALUES (1,'Imprint','Article subtitle','imprint','','Jon Doe','<h4>Contact</h4>\n\n<p>&emsp;Jon Doe<br />\n&emsp;Any rRoad 123<br />\n&emsp;1234 Springfield<br />\n&emsp;+1-1234/56789<br />\n&emsp;<a href=\"mailto:jon.doe@example.com\">jon.doe@example.com</a></p>\n\n<h4>License terms</h4>\n\n<p>Do what ever you want to do!</p>','<p>This text is only visible in full view of article.</p>','2013-10-27 21:50:00','2013-10-27 22:30:14','page','published','','Insert your notes here. Will not be published.',0,NULL,'no');
INSERT INTO `articles` VALUES (2,'First Article','Article subtitle','first_article','','Jon Doe','<p>This is my first article of this tiny website!</p>\n\n<p>This website was made with <strong>Perl</strong> PerlPress, a software\nwritten in Perl that generates static HTML pages from a database.</p>','<p>PerlPress has no GUI, but a neat little command line interface. You can\nsee it in the screenshot below:</p>\n\n<figure>\n<img alt=\"PerlPress Screenshot\" src=../img/perlpress.png width=\"500\" />\n<figcaption>PerlPress Screenshot - easier to use as you might think!\n</figcaption>\n</figure>\n\n<p>PerlPress is easier to use as you might think!</p>','2013-10-27 21:55:21','2013-10-27 22:03:59','blog','published','','Insert your notes here. Will not be published.',0,NULL,'no');
INSERT INTO `articles` VALUES (3,'Second Article','Article subtitle','second_article','','Jon Doe','<p>As time went by, I wrote the second article. You may have noticed my\n{article id=\"2\"}first article{/article}.</p>','<p>I really look forward to add more articles.</p>\n\n<p>Do you know, that you can define you own fancy CSS stuff?</p>\n\n<If I - for instance - add this code:</p>\n\n<div class=\"code\">\n&lt;div class=&quot;code&quot;&gt;<br />\nmy $test=&quotTestvariable&quot;;<br />\n&lt;/div&gt;\n</div>\n\n<p>... I got this on the website:</p>\n\n<div class=\"code\">\nmy $test=&quotTestvariable&quot;;\n</div>\n\n<p>It\'s nice, isn\'t it?</p>','2013-10-27 22:02:40','2013-10-27 22:30:34','blog','published','','Insert your notes here. Will not be published.',0,NULL,'no');
INSERT INTO `articles` VALUES (4,'Definition of shortcuts','Article subtitle','definition_of_shortcuts','','Jon Doe','<p>In PerlPress you can define shortcuts to ease you article coding</p>','<p>For instance, type the following code in the article text:</p>\n\n<div class=\"code\">\n&lbrace;youtube&rbrace;acay3S2PhSg&lbrace;/youtube&rbrace;\n</div>\n\n<p>PerlPress will automatically replace it with the proper HTML code to\ninclude the YouTUBE Video. This is the final result:</p>\n\n{youtube}acay3S2PhSg{/youtube}\n\n<p>All you have to know is the video ID.</p>','2013-10-27 22:45:46','2013-10-27 22:45:46','blog','published','','Insert your notes here. Will not be published.',0,NULL,'no');
/*!40000 ALTER TABLE `articles` ENABLE KEYS */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categories` (
  `cat_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `cat_name` varchar(80) COLLATE utf8_bin DEFAULT NULL,
  `alias` text COLLATE utf8_bin NOT NULL,
  `icon` text COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`cat_id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES (1,'blog','blog','');
INSERT INTO `categories` VALUES (2,'news','news','');
INSERT INTO `categories` VALUES (3,'perlpress','perlpress','');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;

--
-- Table structure for table `html_shortcuts`
--

DROP TABLE IF EXISTS `html_shortcuts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `html_shortcuts` (
  `short_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `descr` varchar(80) COLLATE utf8_bin NOT NULL,
  `find` mediumtext COLLATE utf8_bin NOT NULL,
  `repl` mediumtext COLLATE utf8_bin NOT NULL,
  `enabled` enum('yes','no') COLLATE utf8_bin NOT NULL DEFAULT 'no',
  PRIMARY KEY (`short_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `html_shortcuts`
--

/*!40000 ALTER TABLE `html_shortcuts` DISABLE KEYS */;
INSERT INTO `html_shortcuts` VALUES (1,'Youtube','{youtube}(?<id>.*){/youtube}','<div id=\\\"video\\\"><iframe width=\\\"560\\\" height=\\\"315\\\" src=\\\"http://www.youtube.com/embed/$+{id}\\\" frameborder=\\\"0\\\" allowfullscreen></iframe></div>','yes');
/*!40000 ALTER TABLE `html_shortcuts` ENABLE KEYS */;

--
-- Table structure for table `old_urls`
--

DROP TABLE IF EXISTS `old_urls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `old_urls` (
  `art_id` int(11) unsigned NOT NULL,
  `old_url` text COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`art_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `old_urls`
--

/*!40000 ALTER TABLE `old_urls` DISABLE KEYS */;
/*!40000 ALTER TABLE `old_urls` ENABLE KEYS */;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tags` (
  `tag_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tag_name` varchar(80) COLLATE utf8_bin NOT NULL DEFAULT '',
  `alias` text COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`tag_id`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tags`
--

/*!40000 ALTER TABLE `tags` DISABLE KEYS */;
INSERT INTO `tags` VALUES (1,'imprint','imprint');
INSERT INTO `tags` VALUES (2,'news','news');
INSERT INTO `tags` VALUES (3,'blog','blog');
INSERT INTO `tags` VALUES (4,'perlpress','perlpress');
INSERT INTO `tags` VALUES (5,'shortcut','shortcut');
INSERT INTO `tags` VALUES (6,'youtube','youtube');
/*!40000 ALTER TABLE `tags` ENABLE KEYS */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

--
-- Set the privileges to user test
--
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'test'@'localhost';
GRANT SELECT, INSERT, DELETE, UPDATE ON perlpress.* TO test@'localhost' IDENTIFIED BY 'test_secret';
FLUSH PRIVILEGES;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

