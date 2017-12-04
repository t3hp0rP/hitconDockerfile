create user 'ban'@'localhost' identified by 'ban';
create database bandb;
grant all privileges on bandb.* to 'ban'@'localhost';
use bandb;
create table blacklists (ip varchar(255) primary key, payload varchar(255));