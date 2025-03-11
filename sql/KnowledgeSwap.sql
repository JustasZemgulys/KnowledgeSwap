-- Drop tables if they exist
DROP TABLE IF EXISTS rating;
DROP TABLE IF EXISTS comment;
DROP TABLE IF EXISTS unlocked_test;
DROP TABLE IF EXISTS group_test;
DROP TABLE IF EXISTS question_test;
DROP TABLE IF EXISTS answer;
DROP TABLE IF EXISTS unlocked_resource;
DROP TABLE IF EXISTS test;
DROP TABLE IF EXISTS question;
DROP TABLE IF EXISTS group_resource;
DROP TABLE IF EXISTS user_group;
DROP TABLE IF EXISTS resource;
DROP TABLE IF EXISTS "group";
DROP TABLE IF EXISTS "user";

-- Create tables
CREATE TABLE "user" (
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    last_visited DATE NOT NULL,
    points INTEGER NOT NULL,
    points_in_24h INTEGER NOT NULL,
    points_in_week INTEGER NOT NULL,
    points_in_month INTEGER NOT NULL,
    creation_date DATE NOT NULL,
    visibility BOOLEAN NOT NULL -- 0: not visible, 1: visible
);

CREATE TABLE "group" (
    id INTEGER PRIMARY KEY NOT NULL,
    creation_date DATETIME NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL
);

CREATE TABLE resource (
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    resource_link VARCHAR(255) NOT NULL,
    creation_date DATETIME NOT NULL,
    visibility BOOLEAN NOT NULL,
    resource_photo_link VARCHAR(255) NOT NULL,
    fk_user INTEGER NOT NULL,
    FOREIGN KEY (fk_user) REFERENCES "user" (id)
);

CREATE TABLE user_group (
    id INTEGER PRIMARY KEY NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_group INTEGER NOT NULL,
    role BOOLEAN NOT NULL, -- 0: creator, 1: regular user
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_group) REFERENCES "group" (id)
);

CREATE TABLE group_resource (
    id INTEGER PRIMARY KEY NOT NULL,
    fk_resource INTEGER NOT NULL,
    fk_group INTEGER NOT NULL,
    FOREIGN KEY (fk_group) REFERENCES "group" (id),
    FOREIGN KEY (fk_resource) REFERENCES resource (id)
);

CREATE TABLE question (
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    creation_date DATETIME NOT NULL,
    visibility BOOLEAN NOT NULL,
    answer VARCHAR(255) NULL,
    answer_link VARCHAR(255) NULL,
    fk_user INTEGER NOT NULL,
    fk_resource INTEGER NOT NULL,
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_resource) REFERENCES resource (id)
);

CREATE TABLE test (
    id INTEGER PRIMARY KEY NOT NULL,
    name VARCHAR(255) NOT NULL,
    description VARCHAR(255) NOT NULL,
    creation_date DATETIME NOT NULL,
    visibility BOOLEAN NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_resource INTEGER NOT NULL,
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_resource) REFERENCES resource (id)
);

CREATE TABLE unlocked_resource (
    id INTEGER PRIMARY KEY NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_resource INTEGER NOT NULL,
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_resource) REFERENCES resource (id)
);

CREATE TABLE answer (
    id INTEGER PRIMARY KEY NOT NULL,
    answer VARCHAR(255) NOT NULL,
    answer_link VARCHAR(255) NOT NULL,
    creation_date DATETIME NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_question INTEGER NULL,
    fk_group INTEGER NULL,
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_question) REFERENCES question (id),
    FOREIGN KEY (fk_group) REFERENCES "group" (id)
);

CREATE TABLE question_test (
    id INTEGER PRIMARY KEY NOT NULL,
    fk_question INTEGER NOT NULL,
    fk_test INTEGER NOT NULL,
    FOREIGN KEY (fk_question) REFERENCES question (id),
    FOREIGN KEY (fk_test) REFERENCES test (id)
);

CREATE TABLE group_test (
    id INTEGER PRIMARY KEY NOT NULL,
    fk_test INTEGER NOT NULL,
    fk_group INTEGER NOT NULL,
    FOREIGN KEY (fk_group) REFERENCES "group" (id),
    FOREIGN KEY (fk_test) REFERENCES test (id)
);

CREATE TABLE unlocked_test (
    id INTEGER PRIMARY KEY NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_test INTEGER NOT NULL,
    completed BOOLEAN NOT NULL,
    FOREIGN KEY (fk_test) REFERENCES test (id),
    FOREIGN KEY (fk_user) REFERENCES "user" (id)
);

CREATE TABLE comment (
    id INTEGER PRIMARY KEY NOT NULL,
    comment VARCHAR(255) NOT NULL,
    comment_link VARCHAR(255) NOT NULL,
    creation_date DATETIME NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_comment INTEGER NULL,
    fk_answer INTEGER NULL,
    fk_resource INTEGER NULL,
    fk_question INTEGER NULL,
    fk_test INTEGER NULL,
    fk_group INTEGER NULL,
    FOREIGN KEY (fk_group) REFERENCES "group" (id),
    FOREIGN KEY (fk_resource) REFERENCES resource (id),
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_test) REFERENCES test (id),
    FOREIGN KEY (fk_question) REFERENCES question (id),
    FOREIGN KEY (fk_answer) REFERENCES answer (id),
    FOREIGN KEY (fk_comment) REFERENCES comment (id)
);

CREATE TABLE rating (
    id INTEGER PRIMARY KEY NOT NULL,
    direction BOOLEAN NOT NULL,
    fk_user INTEGER NOT NULL,
    fk_resource INTEGER NULL,
    fk_question INTEGER NULL,
    fk_test INTEGER NULL,
    fk_comment INTEGER NULL,
    fk_answer INTEGER NULL,
    FOREIGN KEY (fk_user) REFERENCES "user" (id),
    FOREIGN KEY (fk_resource) REFERENCES resource (id),
    FOREIGN KEY (fk_question) REFERENCES question (id),
    FOREIGN KEY (fk_test) REFERENCES test (id),
    FOREIGN KEY (fk_comment) REFERENCES comment (id),
    FOREIGN KEY (fk_answer) REFERENCES answer (id)
);
