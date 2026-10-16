CREATE TABLE estoque (
    id SERIAL PRIMARY KEY,
    nome_item VARCHAR(100) NOT NULL,
    quantidade INT NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION fn_valida_estoque_minimo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantidade < 0 THEN
        RAISE EXCEPTION 'Operação cancelada! O item "%" não pode ter estoque negativo (Tentativa: % unidade(s)).', 
            NEW.nome_item, NEW.quantidade;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_estoque
BEFORE INSERT OR UPDATE ON estoque
FOR EACH ROW
EXECUTE FUNCTION fn_valida_estoque_minimo();

CREATE TABLE contas (
    id SERIAL PRIMARY KEY,
    cliente VARCHAR(100) NOT NULL,
    saldo NUMERIC(10, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE movimentações (
    id SERIAL PRIMARY KEY,
    conta_id INT REFERENCES contas(id),
    tipo VARCHAR(1) CHECK (tipo IN ('C', 'D')),
    valor NUMERIC(10, 2) NOT NULL,
    data_movimentacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_atualiza_saldo_conta()
RETURNS TRIGGER AS $$
BEGIN
IF NEW.tipo = 'C' THEN
        UPDATE contas SET saldo = saldo + NEW.valor WHERE id = NEW.conta_id;
    ELSIF NEW.tipo = 'D' THEN
        UPDATE contas SET saldo = saldo - NEW.valor WHERE id = NEW.conta_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualiza_saldo
AFTER INSERT ON movimentações
FOR EACH ROW
EXECUTE FUNCTION fn_atualiza_saldo_conta();