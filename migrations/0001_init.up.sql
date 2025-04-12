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

-- Функция обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW IS DISTINCT FROM OLD THEN
        NEW.updated_at = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Функция аудита
CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log(table_name, operation, new_data, user_id)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(NEW), NEW.updated_by);
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log(table_name, operation, old_data, new_data, user_id)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW), NEW.updated_by);
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log(table_name, operation, old_data, user_id)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), OLD.updated_by);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггеры обновления updated_at
CREATE TRIGGER trg_users_updated
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_receptions_updated
BEFORE UPDATE ON receptions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_products_updated
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- Триггеры аудита
CREATE TRIGGER trg_users_audit
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trg_pvz_audit
AFTER INSERT OR UPDATE OR DELETE ON pvz
FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trg_receptions_audit
AFTER INSERT OR UPDATE OR DELETE ON receptions
FOR EACH ROW EXECUTE FUNCTION log_audit();

CREATE TRIGGER trg_products_audit
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW EXECUTE FUNCTION log_audit();
