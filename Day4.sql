/*
	MySQL 사용자
    1. 사용자 추가하기
		- MySQL 8.0 Commane Line Client 'root' 계정으로 로그인
		- 로컬에서 접속 가능한 사용자 추가하기
			create user '사용자명'@'localhost' identified by '사용자 비밀번호';
            create user 'apple'@'localhost' identified by '1111';
		- DB 권한 부여하기
			grant all privileges on *.* to '사용자'@'localhost'; # 모든 DB에서 접근 가능
			grant all privileges on 데이터베이스명.* to '사용자'@'localhost';
            flush privileges; # 새로운 세팅을 적용함
            
		✅ 할당 권한 상세 옵션
        create, drop, alter: 테이블에 대한 생성, 삭제, 변경 권한
        select, insert, update, delete: 테이블의 데이터를 조회, 삽입, 변경, 삭제에 대한 권한
        all: 모든 권한
        usage: 권한을 부여하지 않고 계정만 생성
        예) grant select, .. on 데이터베이스명.테이블명 to '사용자'@'localhost';
        
        ✅ IP 권한 상세 옵션
        %: 모든 IP에서 접근이 가능
        127.0.0.1: localhost에서 접근이 가능
        예) grant select, .. on 데이터베이스명.테이블명 to '사용자'@'%';
        예) grant select, .. on 데이터베이스명.테이블명 to '사용자'@'특정 ip주소';
        
	2. 사용자 계정 삭제하기
		drop user '사용자명'@'localhost';
*/
grant all privileges on *.* to 'apple'@'localhost';

# 문제
# apple 데이터베이스에 kdt.member 테이블을 복사하고 해당 테이블의 select 권한만 가능한 orange 계정을 만들어보자.
use apple;
create table apple.member(select * from kdt.member);
create user 'orange'@'localhost' identified by '1111';
grant select on apple.member to 'orange'@'localhost';
flush privileges;

drop user 'apple'@'localhost';
drop user 'orange'@'localhost';
create database apple;



# orange로 로그인 후 테스트
use apple;
select * from member;
update member set point = 500 where userid='berry'; # Error Code: 1142. UPDATE command denied to user 'orange'@'localhost' for table 'member'

# 사용자 목록 조회
use mysql;
select user, host from user;

# 사용자 제거
# drop user 계정명; # 추천!
# delete from user where user=계정명;

# 사용자 권한 조회하기
# show grants for '계정명'@'localhost';
show grants for 'apple'@'localhost';
show grants for 'orange'@'localhost';

# 사용자 권한 제거하기
# revoke 권한명 privileges on 데이터베이스명.테이블명 from '계정명'@'localhost';
revoke all privileges on *.* from 'apple'@'localhost';

/*
	뷰(View)
    - 가상의 테이블을 생성
    - 실제 테이블처럼 행과 열을 가지고 있지만, 데이터를 직접 저장하고 있지는 않음
    
    뷰를 만드는 이유
    - SQL 코드를 간결하게 만들기 위함
    - 삽입, 삭제, 수정 작업에 제한 사항을 가짐
    - 내부 데이터를 전체 공개하고 싶지 않을 때
*/
# create view 뷰이름 as 쿼리 ...
use kdt;
select * from member;
select userid, username, hp, gender from member;
create view vw_member as select userid, username, hp, gender from member;
select * from vw_member;

# 문제
# member의 userid, username, hp와 profile의 mbti를 출력하는 뷰(vw_memberprofile)를 만들고 select만 할 수 있는 melon 계정을 생성
select * from profile;
select m.userid, m.username, m.hp, p.mbti from member as m inner join profile as p on m.userid = p.userid;

create view vw_memberprofile as select m.userid, m.username, m.hp, p.mbti from member as m inner join profile as p on m.userid = p.userid;
select * from vw_memberprofile;

create user 'melon'@'localhost' identified by '1111';
grant select on kdt.vw_memberprofile to 'melon'@'localhost';
flush privileges;

# melon으로 접속 후 테스트
use kdt;
select * from member; # Error Code: 1142. SELECT command denied to user 'melon'@'localhost' for table 'member'
select * from vw_memberprofile;

/*
	뷰 수정하기
    alter view 뷰이름 as 쿼리 ...
    
    뷰 대체
    create or replace view 뷰이름 as 쿼리 ...
*/

use kdt;
create or replace view vw_memberprofile as select m.userid, m.username, m.hp, p.mbti from member as m inner join profile as p on m.userid = p.userid;

# 뷰 삭제하기
# drop view 뷰이름;
drop view vw_member;
select * from vw_member;

update vw_member set hp='01000000000' where userid='berry';
select * from vw_member; # 뷰 전화번호 데이터 변경됨
select * from member;

# Error Code: 1423. Field of view 'kdt.vw_member' underlying table doesn't have a default value
insert into vw_member values('avocado', '안가도', '01088888888', '남자'); # 테이블 not null 제약조건으로 인해 데이터 삽입이 안됨

/*
	트랜젝션(Transaction)
    - 분할이 불가능한 업무처리의 단위
    - 한꺼번에 수행되어야 할 연산 모음
    
    commit: 모든 작업들을 정상 처리하겠다고 확정하는 명령어로서, 해당 처리 과정을 DB에 영구적으로 저장
    rollback: 작업 중 문제가 발생되어 트랜젝션의 처리과정에서 발생한 변경사항을 모두 취소하는 명령어
    
    start transaction
		블록안의 명령어들은 하나의 명령어처럼 처리됨
        ...
        성공하던지, 실패하던지 둘 중 하나의 결과가 됨
        문제가 발생하면 rollbak;
	정상 적인 처리가 완료되면 commit;
    
    트랜젝션의 특징
    - 원자성: 트랜젝션이 데이터베이스에 모두 반영되던가, 아니면 전혀 반영되지 않아야 함
    - 일관성: 트랜젝션의 작업 처리 결과가 항상 일관성이 있어야 함
    - 독립성: 어떤 하나의 트랜젝션이라도, 다른 트랜젝션의 연산에 끼어들 수 없음
    - 영구성: 결과는 영구적으로 반영되어야 함
    
*/
# 자동 커밋 확인
show variables like '%commit%';
# autocommit: ON -> 자동으로 commit 해줌
# set autocommit=0 (off), set autocommit=1 (on)
set autocommit = 0;

select * from product;
start transaction; # 트랜젝션의 시작. commit 또는 rollbak으로 끝내야 함
insert into product values ('100005', '고철', '팔아요', 100, now());
select * from product;
commit; # 트랜잭션을 DB에 적용


start transaction;
insert into product values ('100006', '공병', '팔아요', 50, now());
select * from product;
rollback; # 트램젝션을 취소하고 start transaction 실행 전 상태로 롤백함
select * from product;

# 트랜젝션의 예외
# DDL문에(create, drop, alter, rename, truncate) 대해 예외를 적용 -> rollback 대상이 아님

# truncate
# 개별적으로 행을 삭제할 수 없으며, 테이블 내부의 모든 행(데이터)를 삭제
# rollback이 불가능
# 트랜젝션 로그에 한 번만 기록하므로 delete 구문보다 성능 면에서 빠름
# truncate table 테이블명 = delete from 테이블명
select * from product_new;
start transaction;
delete from product_new;
select * from product_new;
rollback;

start transaction;
truncate table product_new;
select * from product_new;
rollback;

set autocommit=1;
show variables like '%commit%';

/*
	인덱스(index)
    - 테이블의 동작속도(조회)를 높여주는 자료구조
    - 데이터의 위치를 빠르게 찾아주는 역할
    - MYI(MySQL Index)파일에 저장
    - 인덱스를 설정하지 않으면 Table Full Scan이 일어나 성능이 저하되거나 장애가 발생할 수 있음
    - 조회속도는 빨라지지만 update, insert, delete의 속도는 저하될 수 있음
    - MySQL에서는 primary key, unique 제약조건을 사용하면 해당 컬럼에 index가 적용됨
    - 인덱스는 하나 또는 여러 개의 컬럼에 설정할 수 있음
    - where절을 사용하지 않고 인덱스가 걸린 컬럼을 조회하면 성능에 아무런 효과가 없음
    - 가급적 update가 안되는 값을 설정하는 것이 좋음
    
    oreder by, group by와 index
    - oreder by 인덱스컬럼, 일반컬럼: 복수의 키에 대해 oreder by를 상용한 경우
    - where 일반컬럼='값' order by 인덱스컬럼: 연속하지 않은 컬럼에 대해 order by를 실행한 경우
    - order by 인덱스컬럼1 desc, 인덱스컬럼2 asc: desc와 asc를 혼합해서 사용한 경우
    - group by 일반컬럼1 order by 인덱스컬럼: group by와 order by의 컬럼이 다른 경우
    - order by 함수(인덱스컬럼): order by 절에 컬럼이 아닌 다른 표현을 사용한 경우
    
    인덱스 문법
    create index 인덱스명 on 테이블명(필드이름)
    create index 인덱스명 on 테이블명(필드이름1, 필드이름2 ...)
    
    인덱스 조회하기
    show index from 테이블명
    
    인덱스 삭제하기
    alter table 테이블명 drop index 인덱스명;
    
*/
select * from member;
show index from member;

create index idx_hp on member(hp);
alter table member drop index idx_hp;











