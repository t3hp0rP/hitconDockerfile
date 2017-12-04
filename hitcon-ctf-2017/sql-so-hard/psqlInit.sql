create user userdb with password 'userdb';
create database userdb owner userdb;
\c userdb;
create table users (username varchar(255) primary key, password varchar(255));