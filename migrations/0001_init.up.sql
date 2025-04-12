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

-- Таблица пользователей
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email CITEXT NOT NULL,
    password_hash VARCHAR(255) NOT NULL CHECK (length(password_hash) >= 8),
    role user_role NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_email CHECK (
        email ~* '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$'
    )
);

COMMENT ON COLUMN users.password_hash IS 'Хэш пароля пользователя';

CREATE UNIQUE INDEX idx_users_email_unique ON users (email);

-- Таблица ПВЗ
CREATE TABLE pvz (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    city city_enum NOT NULL,
    registration_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Таблица приемок
CREATE TABLE receptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    pvz_id UUID NOT NULL,
    status reception_status NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pvz_id) REFERENCES pvz(id) ON DELETE CASCADE,
    CONSTRAINT unique_active_reception 
        EXCLUDE USING gist (pvz_id WITH =) 
        WHERE (status = 'in_progress'),
    CONSTRAINT valid_reception_timeline CHECK (date_time <= created_at)
);

COMMENT ON CONSTRAINT valid_reception_timeline ON receptions IS 'Проверка корректности временных меток';

CREATE INDEX idx_receptions_status ON receptions(status);

-- Таблица товаров
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    type product_type NOT NULL,
    reception_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantity INT NOT NULL CHECK (quantity > 0) DEFAULT 1,
    FOREIGN KEY (reception_id) REFERENCES receptions(id) ON DELETE CASCADE,
    CONSTRAINT valid_product_timeline CHECK (date_time <= created_at)
);

COMMENT ON COLUMN products.quantity IS 'Количество единиц товара';

CREATE INDEX idx_products_type_created ON products(type, created_at);

-- Таблица аудита
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    user_id UUID REFERENCES users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN audit_log.user_id IS 'Пользователь, совершивший изменение';