drop table clones;
create table clones (
       id int primary key auto_increment,
       clone_name text not null,
       allele_name_superscript_template text,
       allele_type text
       ) engine = innodb;

drop table mi_attempts;
create table mi_attempts (
       id int primary key auto_increment,
       colony_name text not null,
       mouse_allele_type text,
       clone_id int not null
       ) engine = innodb;


insert into clones values (1, 'EPD0127_4_E01', 'tm1@(EUCOMM)Wtsi', 'a');
insert into clones values (2, 'EPD0127_4_F01', 'tm1@(EUCOMM)Wtsi', NULL);
insert into clones values (3, 'EPD0127_4_G01', 'tm1(EUCOMM)Wtsi', NULL);

insert into mi_attempts (colony_name, mouse_allele_type, clone_id)
       values           ('ABC1', null, 1);

insert into mi_attempts (colony_name, mouse_allele_type, clone_id)
       values           ('DEF1', null, 2);

insert into mi_attempts (colony_name, mouse_allele_type, clone_id)
       values           ('GHI1', 'e', 1);

insert into mi_attempts (colony_name, mouse_allele_type, clone_id)
       values           ('JKL1', 'a', 3);


drop view mi_attempts_view;
create view mi_attempts_view as
select clones.allele_name_superscript_template,
       clones.allele_type,
       REPLACE(clones.allele_name_superscript_template, '@', IFNULL(clones.allele_type, '')) AS allele_name_superscript,
       REPLACE(clones.allele_name_superscript_template, '@', mouse_allele_type) AS mouse_allele_name_superscript,
       mi_attempts.*
from mi_attempts
inner join clones on clones.id = mi_attempts.clone_id;


select * from mi_attempts_view order by id\G
