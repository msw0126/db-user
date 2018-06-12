drop database if EXISTS databrain;
create database databrain DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

drop database if EXISTS engine;
create database engine DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

use databrain;

DELIMITER $$
--
-- Definition for procedure pp_addcolumn
--
DROP PROCEDURE IF EXISTS pp_addcolumn$$

CREATE PROCEDURE pp_addcolumn (IN p_table_name      varchar(50),
                                   IN p_column_name     varchar(50),
                                   IN p_pre_column_name varchar(50),
                                   IN p_column_type     varchar(15),
                                   IN p_is_null         int,
                                   IN p_default_value   varchar(255),
                                   IN p_column_comments varchar(255))
lable_pp_addcolumn: BEGIN
  /*
	 * p_table_name 目标表名
	 * p_column_name 目标列名
	 * p_pre_column_name 前置列名,新增列放在哪一列的后面
   * p_column_type 目标列数据类型
   * p_is_null 目标列是否可为空（新增时才有效） 1-是，0-否
   * p_default_value 目标列默认值
   * p_column_comments 目标列注释
	 */

  -- 数量
  DECLARE v_count int;
  -- 数据库名
  DECLARE v_curr_db_name varchar(50);
  -- 待执行的动态SQL语句
  DECLARE v_sql text;
  -- 定义错误标识
  DECLARE _err int DEFAULT 0;
  -- 异常处理
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION, SQLWARNING, NOT FOUND SET _err = 1;

  -- 获得数据库名
  SELECT
    DATABASE() INTO v_curr_db_name;

  -- 1 判断表是否存在
  SELECT
    COUNT(1) INTO v_count
    FROM information_schema.TABLES T
    WHERE T.TABLE_SCHEMA = v_curr_db_name
      AND T.TABLE_NAME = p_table_name;

  -- 1.1 如果不存在，则返回提示信息
  IF v_count = 0 THEN
    -- RETURN CONCAT('0-当前数据库', v_curr_db_name, '中，表', p_table_name, '不存在。');
    LEAVE lable_pp_addcolumn;
  END IF;

  -- 1.2 拼接SQL中，表名部分
  SET v_sql = CONCAT('ALTER TABLE ', p_table_name, ' ');

  -- 2 判断列是否存在
  SELECT
    COUNT(1) INTO v_count
    FROM information_schema.COLUMNS C
    WHERE C.TABLE_SCHEMA = v_curr_db_name
      AND C.TABLE_NAME = p_table_name
      AND C.COLUMN_NAME = p_column_name;

  -- 3 拼接列名部分
  -- 如果不存在，则新增列,否则修改列
  IF v_count = 0 THEN
    SET v_sql = CONCAT(v_sql, 'ADD COLUMN ', p_column_name, ' ', p_column_type, ' ');
    -- 4 新增时，需要判断字段是否可为空
    IF p_is_null = 0 THEN
      SET v_sql = CONCAT(v_sql, 'NOT ');
    END IF;
    SET v_sql = CONCAT(v_sql, 'NULL ');
  ELSE
    -- 修改字段时，字段可为空
    SET v_sql = CONCAT(v_sql, 'MODIFY COLUMN ', p_column_name, ' ', p_column_type, ' NULL ');
  END IF;

  -- 5 默认值
  IF p_default_value IS NOT NULL THEN
    SET v_sql = CONCAT(v_sql, ' DEFAULT ', p_default_value, ' ');
  END IF;

  -- 6 注释
  IF p_column_comments IS NOT NULL THEN
    SET v_sql = CONCAT(v_sql, ' COMMENT "', p_column_comments, '" ');
  END IF;

  -- 7 根据前导字段，拼接添加到的位置部分
  SELECT
    COUNT(1) INTO v_count
    FROM information_schema.COLUMNS C
    WHERE C.TABLE_SCHEMA = v_curr_db_name
      AND C.TABLE_NAME = p_table_name
      AND C.COLUMN_NAME = p_pre_column_name;
  -- 7.1 存在就添加位置控制
  IF v_count > 0 THEN
    SET v_sql = CONCAT(v_sql, ' AFTER ', p_pre_column_name, ' ');
  END IF;

  -- 8 执行动态SQL,添加或修改列
  SET @v_sql := v_sql;
  -- ##预处理动态SQL
  PREPARE stmt FROM @v_sql;
  -- ##执行SQL语句
  EXECUTE stmt;
  -- ## 释放动态SQL
  DEALLOCATE PREPARE stmt;

END
$$

DELIMITER ;


-- 注册审核表
DROP TABLE IF EXISTS `sys_user_apply`;
CREATE TABLE `sys_user_apply` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '申请ID',
  `real_name` VARCHAR(60) DEFAULT NULL COMMENT '真实姓名',
  `company` VARCHAR(100) DEFAULT NULL COMMENT '公司名称',
  `position` VARCHAR(60) DEFAULT NULL COMMENT '职称',
  `user_type` CHAR(1) DEFAULT NULL COMMENT '用户类型',
  `address` VARCHAR(200) DEFAULT NULL COMMENT '地址',
  `email` VARCHAR(200) DEFAULT NULL COMMENT '邮箱',
  `mobile` VARCHAR(11) DEFAULT NULL COMMENT '手机号',
  `password` VARCHAR(255) DEFAULT NULL COMMENT '密码',
  `ip` VARCHAR(60) DEFAULT NULL COMMENT 'IP',
  `audit_state` CHAR(1) DEFAULT NULL COMMENT '审核状态',
  `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
  `create_time` BIGINT(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
-- 客户信息表
DROP TABLE  IF EXISTS `sys_user_info`;
DROP TABLE IF EXISTS `customer_info`;
CREATE TABLE `customer_info` (
  `customer_id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '自增主键',
  `real_name` VARCHAR(60) DEFAULT NULL COMMENT '真实姓名',
  `company` VARCHAR(100) DEFAULT NULL COMMENT '公司',
  `position` VARCHAR(60) DEFAULT NULL COMMENT '身份',
  `address` VARCHAR(200) DEFAULT NULL COMMENT '地址',
  PRIMARY KEY (`customer_id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;#Table structure for sys_dict_entry
#----------------------------
#DROP TABLE IF EXISTS sys_dict_entry;
CREATE TABLE IF NOT EXISTS sys_dict_entry (
  dict_entry_code varchar(16) NOT NULL,
  dict_entry_name varchar(32) NOT NULL,
  ctrl_flag varchar(8) default NULL,
  lifecycle varchar(8) default NULL,
  platform varchar(8) default NULL,
  remark varchar(256) default NULL,
  PRIMARY KEY  (dict_entry_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


#----------------------------
#Table structure for sys_dict_item
#----------------------------
#DROP TABLE IF EXISTS sys_dict_item;
CREATE TABLE IF NOT EXISTS sys_dict_item (
  dict_item_code varchar(32) NOT NULL,
  dict_entry_code varchar(16) NOT NULL,
  dict_item_name varchar(60) NOT NULL,
  platform varchar(8) default NULL,
  dict_item_order bigint(20) default NULL,
  rel_code varchar(16) default NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#Table structure for sys_dict_entry
#----------------------------
DROP TABLE IF EXISTS sys_dict_entry;
CREATE TABLE IF NOT EXISTS sys_dict_entry (
  dict_entry_code varchar(16) NOT NULL,
  dict_entry_name varchar(32) NOT NULL,
  ctrl_flag varchar(8) default NULL,
  lifecycle varchar(8) default NULL,
  platform varchar(8) default NULL,
  remark varchar(256) default NULL,
  PRIMARY KEY  (dict_entry_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
#----------------------------
#Table structure for sys_menu
#----------------------------
DROP TABLE IF EXISTS sys_menu;
CREATE TABLE IF NOT EXISTS sys_menu (
  menu_code varchar(32) NOT NULL,
  menu_name varchar(32) NOT NULL,
  menu_arg varchar(256) default NULL,
  menu_icon varchar(256) default NULL,
  menu_url varchar(256) default NULL,
  parent_code varchar(32) default NULL,
  order_no bigint(20) default NULL,
  tree_idx varchar(256) default NULL,
  remark varchar(256) default NULL,
  PRIMARY KEY  (menu_code),
  KEY INDX_BIZ_MENU_CODE (menu_code),
  KEY INDX_BIZ_MENU_PCODE (parent_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for sys_menu_role
#----------------------------
#DROP TABLE IF EXISTS sys_menu_role;
CREATE TABLE IF NOT EXISTS sys_menu_role (
  menu_code varchar(32) NOT NULL,
  role_code varchar(16) NOT NULL,
  PRIMARY KEY  (menu_code,role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for sys_org_user
#----------------------------
DROP TABLE IF EXISTS sys_org_user;
CREATE TABLE IF NOT EXISTS tsys_org_user (
  user_id bigint NOT NULL,
  org_id bigint NOT NULL,
  PRIMARY KEY  (user_id,org_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for sys_organization
#----------------------------
DROP TABLE IF EXISTS sys_organization;
CREATE TABLE IF NOT EXISTS sys_organization (
  org_id bigint not null auto_increment comment '自增主键',
  org_code varchar(32) default NULL,
  org_name varchar(32) default NULL,
  parent_id varchar(40) default NULL,
  org_level varchar(8) default NULL,
  org_order int(11) default NULL,
  remark varchar(256) default NULL,
  status int default 0,
  PRIMARY KEY  (org_id),
  KEY INDX_BIZ_ORG_CODE (org_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for sys_role
#----------------------------
#DROP TABLE IF EXISTS sys_role;
CREATE TABLE IF NOT EXISTS sys_role (
  role_code varchar(16) NOT NULL,
  role_name varchar(64) default NULL,
  creator varchar(32) default NULL,
  remark varchar(256) default NULL,
  role_order int default 0,
  create_date int default null,
  create_time int default null,
  modify_date int default null,
  modify_time int default null,
  PRIMARY KEY  (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


#----------------------------
#Table structure for sys_role_user
#----------------------------
DROP TABLE IF EXISTS sys_role_user;
CREATE TABLE IF NOT EXISTS sys_role_user (
  user_id bigint NOT NULL,
  role_code varchar(16) NOT NULL,
  PRIMARY KEY  (user_id,role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for sys_user
#----------------------------
DROP TABLE IF EXISTS sys_user;
CREATE TABLE IF NOT EXISTS sys_user (
  user_id bigint not null auto_increment comment '自增主键',
  customer_id bigint(20) default null,
  user_name varchar(32) NOT NULL UNIQUE,
  user_nick_name varchar(64) NOT NULL ,
  user_pwd varchar(255) NOT NULL,
  user_type varchar(32) NOT NULL,
  user_status varchar(8) NOT NULL,
  lock_status varchar(8) NOT NULL,
  create_date bigint(20) NOT NULL,
  modify_date bigint(20) default NULL,
  pass_modify_date bigint(20) default NULL,
  mobile varchar(32) default NULL,
  email varchar(256) default NULL,
  ext_flag varchar(8) default NULL,
  remark varchar(256) default NULL,
  user_order int(11) default NULL,
  user_token varchar(32),
  validate_time bigint,
  identitytype varchar(3),
  identityno  varchar(40),
  credentials varchar(40),
  create_time int default null,
  modify_time int default null,
  org_id varchar(40),
  PRIMARY KEY  (user_id),
  KEY INDX_BIZ_USER_NAME USING BTREE (user_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;-- 修改表结构，新增customer_id字段
CREATE TABLE `sys_user_info` (
 `user_id` bigint(20) NOT NULL,
 `real_name` varchar(60) DEFAULT NULL COMMENT '真实姓名',
 `company` varchar(100) DEFAULT NULL COMMENT '公司',
 `position` varchar(60) DEFAULT NULL COMMENT '身份',
 `address` varchar(200) DEFAULT NULL COMMENT '地址',
 PRIMARY KEY (`user_id`),
 CONSTRAINT `fpk_user_id` FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




DROP TABLE if EXISTS sys_user_message;
CREATE TABLE `sys_user_message` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `send_person` varchar(255) DEFAULT NULL,
  `status` char(1) DEFAULT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `create_time` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#Table structure for sys_verify
#----------------------------
#DROP TABLE IF EXISTS sys_verify;
CREATE TABLE IF NOT EXISTS sys_verify (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `address` varchar(100) DEFAULT NULL COMMENT '验证地址',
  `type` CHAR(1) NOT NULL COMMENT '(1:邮箱)',
  `verify_code` VARCHAR(4) DEFAULT NULL COMMENT '验证码',
  `verify_status` CHAR(1) DEFAULT NULL COMMENT '(1:已验证;0:未验证)',
  `create_date` BIGINT(20) DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;
DELETE FROM sys_menu WHERE menu_code = 'projectMgr' or parent_code = 'projectMgr';
DELETE FROM sys_menu WHERE menu_code = 'sysMenu' or parent_code = 'sysMenu';

INSERT INTO `sys_menu` VALUES ('projectMgr', '项目管理', NULL, NULL, NULL, 'sysRoot', NULL, '1', '项目管理顶级菜单');
INSERT INTO `sys_menu` VALUES ('projectProdMgr', '生产项目管理', NULL, NULL, 'projectProdMgr', 'projectMgr', 2, NULL, '生产项目管理');
INSERT INTO `sys_menu` VALUES ('projectTrainMgr', '实验项目管理', NULL, NULL, 'trprojectTrainMgr', 'projectMgr', 1, NULL, '实验项目管理');
INSERT INTO `sys_menu` VALUES ('sysMenu', '权限管理', NULL, NULL, NULL, 'sysRoot', NULL, '2', '权限管理顶级菜单');
INSERT INTO `sys_menu` VALUES ('sysUserMgr', '用户管理', NULL, NULL, 'sysUserManager', 'sysMenu', 1, NULL, '用户管理');


commit;DELETE FROM sys_menu WHERE menu_code = 'modelMenu' ;
DELETE FROM sys_menu WHERE menu_code = 'sysModelMgr'  ;

INSERT INTO `sys_menu` VALUES ('modelMenu', '模型管理', NULL, NULL, NULL, 'sysRoot', NULL, '3', '模型管理顶级菜单');
INSERT INTO `sys_menu` VALUES ('sysModelMgr', '模型管理', NULL, NULL, 'sysModelMgr', 'modelMenu', 1, NULL, NULL);

commit;DELETE FROM sys_menu_role WHERE role_code = 'admin';
DELETE FROM sys_menu_role WHERE role_code = 'data_science';
DELETE FROM sys_menu_role WHERE role_code = 'IT_engineer';

# INSERT INTO `sys_menu_role` VALUES ('projectMgr', 'admin');
INSERT INTO `sys_menu_role` VALUES ('projectMgr', 'data_science');
INSERT INTO `sys_menu_role` VALUES ('projectMgr', 'IT_engineer');

# INSERT INTO `sys_menu_role` VALUES ('projectTrainMgr', 'admin');
INSERT INTO `sys_menu_role` VALUES ('projectTrainMgr', 'data_science');
INSERT INTO `sys_menu_role` VALUES ('projectTrainMgr', 'IT_engineer');

INSERT INTO `sys_menu_role` VALUES ('projectProdMgr', 'data_science');
INSERT INTO `sys_menu_role` VALUES ('projectProdMgr', 'IT_engineer');

INSERT INTO `sys_menu_role` VALUES ('sysMenu', 'admin');
INSERT INTO `sys_menu_role` VALUES ('sysUserMgr', 'admin');
DELETE FROM sys_menu_role WHERE menu_code = 'modelMenu';
DELETE FROM sys_menu_role WHERE menu_code = 'sysModelMgr';

INSERT INTO `sys_menu_role` VALUES ('modelMenu', 'admin');
INSERT INTO `sys_menu_role` VALUES ('modelMenu', 'data_science');
INSERT INTO `sys_menu_role` VALUES ('sysModelMgr', 'admin');
INSERT INTO `sys_menu_role` VALUES ('sysModelMgr', 'data_science');

commit;DELETE FROM sys_role WHERE role_code = 'admin';
DELETE FROM sys_role WHERE role_code = 'biz_data';
DELETE FROM sys_role WHERE role_code = 'data_science';
DELETE FROM sys_role WHERE role_code = 'IT_engineer';

INSERT INTO `sys_role` VALUES ('admin', '管理员', 'system', '管理员', 1, NULL, NULL, NULL, NULL);
INSERT INTO `sys_role` VALUES ('biz_data', '数据业务岗', '1', '数据业务岗', 4, NULL, NULL, NULL, NULL);
INSERT INTO `sys_role` VALUES ('data_science', '数据科学家', '1', '数据科学家', 2, NULL, NULL, NULL, NULL);
INSERT INTO `sys_role` VALUES ('IT_engineer', 'IT工程师', '1', 'IT工程师', 3, NULL, NULL, NULL, NULL);
commit;delete from sys_role_user where role_code = 'admin';

INSERT INTO `sys_role_user` VALUES (1, 'admin');

commit;delete from  `sys_user` where user_id = 1;

INSERT INTO `sys_user` VALUES (1, 0,'admin', '系统管理员', '3d4f2bf07dc1be38b20cd6e46949a1071f9d0e3d', 'admin', '1', '0', 1493438691796, NULL, NULL, '15381002810', 'jinchongmin@taodatarobot.com', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

commit;

#文件管理表
 DROP TABLE IF EXISTS biz_pmml_info;
CREATE TABLE
IF NOT EXISTS  biz_pmml_info(
  ID varchar(32) NOT NULL  COMMENT '主键，无业务意义',
  model_name varchar(256) NOT NULL COMMENT '模型名称',
  project_id bigint(20) not null  COMMENT '项目编号',
  project_name varchar(32) ,
  pmml_file_path varchar(256) not null COMMENT '文件路径',
  user_id bigint(32) not null,

  task_id varchar(32) NOT NULL,
  inst_id varchar(32) NOT NULL,
  flow_id varchar(32) NOT NULL,
  act_id varchar(64) not null,

  algorithm varchar(32) NOT NULL,

  create_time bigint   COMMENT '创建日期',
  status varchar(8) COMMENT '状态',
  PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='模型记录文件';#文件管理表
CREATE TABLE
IF NOT EXISTS  biz_project_file(
  ID bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键，无业务意义',
  FILE_NAME varchar(256) DEFAULT NULL COMMENT '文件名称',
  FILE_DESC varchar(256) DEFAULT NULL COMMENT '文件描述',
  FILE_PATH varchar(512) DEFAULT NULL COMMENT '文件路径',
  CREATE_BY varchar(64) DEFAULT NULL COMMENT '创建者',
  CREATE_DATE datetime DEFAULT NULL COMMENT '创建日期',
  FILE_STATUS varchar(8) DEFAULT NULL COMMENT '文件状态',
  FILE_TYPE varchar(8) DEFAULT NULL COMMENT '文件类型',
  FILE_SIZE bigint(20) DEFAULT NULL COMMENT '文件大小',
  FILE_CHUNKS int(11) DEFAULT NULL COMMENT '文件当前块号',
  LAST_CHUNK int(11) DEFAULT NULL COMMENT '文件块总数',
  MD5_KEY varchar(56) DEFAULT NULL COMMENT 'MD5码',
  PROJECT_ID bigint(20) DEFAULT NULL COMMENT '项目编号',
  PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='项目配置文件表';#文件管理表
DROP TABLE IF EXISTS biz_project_file;
CREATE TABLE
IF NOT EXISTS  biz_project_file(
  ID varchar(32) NOT NULL  COMMENT '主键，无业务意义',
  FILE_NAME varchar(256) DEFAULT NULL COMMENT '文件名称',
  FILE_DESC varchar(256) DEFAULT NULL COMMENT '文件描述',
  FILE_PATH varchar(512) DEFAULT NULL COMMENT '文件路径',
  CREATE_BY varchar(64) DEFAULT NULL COMMENT '创建者',
  CREATE_DATE datetime DEFAULT NULL COMMENT '创建日期',
  FILE_STATUS varchar(8) DEFAULT NULL COMMENT '文件状态',
  FILE_TYPE varchar(8) DEFAULT NULL COMMENT '文件类型',
  FILE_SIZE bigint(20) DEFAULT NULL COMMENT '文件大小',
  FILE_CHUNKS int(11) DEFAULT NULL COMMENT '文件当前块号',
  LAST_CHUNK int(11) DEFAULT NULL COMMENT '文件块总数',
  MD5_KEY varchar(56) DEFAULT NULL COMMENT 'MD5码',
  PROJECT_ID bigint(20) DEFAULT NULL COMMENT '项目编号',
  PRIMARY KEY (ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='项目配置文件表';#----------------------------
#Table structure for biz_project_job
#----------------------------
#DROP TABLE IF EXISTS biz_project_job;
CREATE TABLE IF NOT EXISTS biz_project_job (
  job_id varchar(32) NOT NULL,
  job_name varchar(32) NOT NULL,
  job_excute_time varchar(128) NOT NULL,
  job_status varchar(8) NOT NULL,
  prod_id bigint(20) NOT NULL,
  creator bigint(32) default NULL,
  remark varchar(256) default NULL,
  PRIMARY KEY  (job_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for biz_project_prod
#----------------------------
DROP TABLE IF EXISTS biz_project_prod;
CREATE TABLE IF NOT EXISTS biz_project_prod (
  prod_id bigint not null auto_increment comment '自增主键',
  prod_code varchar(32) NOT NULL,
  prod_name varchar(32) NOT NULL,
  prod_type varchar(16) NOT NULL,
  excute_type varchar(16) default NULL,
  prod_status varchar(8) NOT NULL,
  create_date bigint(20) NOT NULL,
  creator_id bigint(32) default NULL,
  creator_name  varchar(32) ,
  job_id bigint  ,
  remark varchar(256) default NULL,
  file_id varchar(32),
  PRIMARY KEY  (prod_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;#----------------------------
#Table structure for biz_project_train
#----------------------------
 DROP TABLE IF EXISTS biz_project_train;
CREATE TABLE IF NOT EXISTS biz_project_train (
  train_id bigint not null auto_increment comment '自增主键',
  train_code varchar(32) NOT NULL,
  train_name varchar(32) NOT NULL,
  train_type varchar(16) NOT NULL,
  project_status varchar(8) NOT NULL,
  create_date bigint(20) NOT NULL,
  creator_id bigint(32) default NULL,
  creator_name  varchar(32) ,
  remark varchar(256) default NULL,
  file_id bigint(64)   ,
  PRIMARY KEY  (train_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;/*Table structure for table `dict_entry` */

DROP TABLE IF EXISTS `dict_entry`;


CREATE TABLE `dict_entry` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `flag` CHAR(1) NOT NULL COMMENT '是否可用(0:否,1:是)',
  `platform` VARCHAR(8) DEFAULT NULL COMMENT '平台',
  `dict_entry_code` VARCHAR(16) NOT NULL COMMENT 'code',
  `dict_entry_name` VARCHAR(32) NOT NULL COMMENT '名称',
  `dict_entry_order` INT(11) DEFAULT NULL COMMENT '排序',
  `remark` VARCHAR(256) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_code` (`dict_entry_code`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;


/*Data for the table `dict_entry` */

/*Table structure for table `dict_item` */

DROP TABLE IF EXISTS `dict_item`;

CREATE TABLE `dict_item` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `tenant_id` BIGINT(20) DEFAULT NULL COMMENT '租户ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户Id',
  `status` CHAR(1) NOT NULL COMMENT '是否可用(0:否,1:是)',
  `color` VARCHAR(20) DEFAULT NULL COMMENT '背景颜色',
  `dict_entry_code` VARCHAR(16) COMMENT 'dict_entry_code',
  `dict_item_code` VARCHAR(32) NOT NULL COMMENT 'code',
  `dict_item_name` VARCHAR(60) NOT NULL COMMENT 'value',
  `dict_item_order` BIGINT(20) DEFAULT NULL COMMENT '排序',
  `remark` VARCHAR(256) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_code` (`tenant_id`,`user_id`,`dict_item_code`),
  CONSTRAINT `fk_dict_entry_code` FOREIGN KEY (`dict_entry_code`) REFERENCES `dict_entry` (`dict_entry_code`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

/*Data for the table `dict_item` */

INSERT INTO dict_entry VALUES(1, '1', '222', '02', '333', 01, '备注');
CALL pp_addcolumn('biz_project_train','color','train_type','VARCHAR(20)',1,NULL,'color');
ALTER TABLE `biz_project_train`
ADD COLUMN `is_product`  char(1) NULL DEFAULT 'N' AFTER `file_id`;
ALTER TABLE `biz_project_train`
ADD COLUMN `product_date`  char(1) NULL AFTER `is_product`;

