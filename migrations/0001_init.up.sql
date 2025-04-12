-- Добавляем расширения
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUM-типы
CREATE TYPE user_role AS ENUM ('employee', 'moderator');
CREATE TYPE city_enum AS ENUM ('Москва', 'Санкт-Петербург', 'Казань');
CREATE TYPE reception_status AS ENUM ('in_progress', 'close');
CREATE TYPE product_type AS ENUM ('электроника', 'одежда', 'обувь');

-- Комментарии к ENUM
COMMENT ON TYPE user_role IS 'Роли пользователей в системе';
COMMENT ON TYPE city_enum IS 'Города размещения ПВЗ';
COMMENT ON TYPE reception_status IS 'Статусы приемки товаров';
COMMENT ON TYPE product_type IS 'Типы принимаемых товаров';
