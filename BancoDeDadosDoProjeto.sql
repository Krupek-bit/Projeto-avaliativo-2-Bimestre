--1
create or replace procedure sistema_pedidos.atualizar_preco_produto(
    p_id_produto int,
    p_novo_valor numeric
)
language plpgsql
as $$
begin
    if p_novo_valor is null or p_novo_valor <= 0 then
        raise notice 'Valor inválido: o novo preço deve ser maior que zero.';
        return;
    end if;

    if not exists (select 1
                     from sistema_pedidos.produto
                    where id_produto = p_id_produto) then
        raise notice 'Produto % não encontrado.', p_id_produto;
        return;
    end if;

    update sistema_pedidos.produto
       set valor_unitario = p_novo_valor
     where id_produto = p_id_produto;

    raise notice 'Preço do produto % atualizado para R$ %.', p_id_produto, p_novo_valor;
end $$;

call sistema_pedidos.atualizar_preco_produto(1, 5299.90);
call sistema_pedidos.atualizar_preco_produto(1, 0);
call sistema_pedidos.atualizar_preco_produto(9999, 100);

--2
create or replace procedure sistema_pedidos.cadastrar_categoria(p_nome varchar)
language plpgsql
as $$
declare
    v_nome varchar := trim(p_nome);
begin
    if v_nome is null or v_nome = '' then
        raise notice 'Nome inválido: informe um nome para a categoria.';
        return;
    end if;

    if length(v_nome) > 50 then
        raise notice 'Nome inválido: máximo de 50 caracteres.';
        return;
    end if;

    if exists (select 1
                 from sistema_pedidos.categoria
                where lower(trim(nome)) = lower(v_nome)) then
        raise notice 'Já existe uma categoria com o nome "%".', v_nome;
        return;
    end if;

    insert into sistema_pedidos.categoria (nome) values (v_nome);

    raise notice 'Categoria "%" cadastrada com sucesso.', v_nome;
end $$;

call sistema_pedidos.cadastrar_categoria('Livros & Revistas');
call sistema_pedidos.cadastrar_categoria('livros & revistas');
call sistema_pedidos.cadastrar_categoria('   ');

--3
create or replace procedure sistema_pedidos.remover_produto(p_id_produto int)
language plpgsql
as $$
begin
    if not exists (select 1
                     from sistema_pedidos.produto
                    where id_produto = p_id_produto) then
        raise notice 'Não foi possível remover: produto % não encontrado.', p_id_produto;
        return;
    end if;

    if exists (select 1
                 from sistema_pedidos.detalhe_pedido
                where produto_id = p_id_produto) then
        raise notice 'Não foi possível remover: produto % está vinculado a pedidos.', p_id_produto;
        return;
    end if;

    delete from sistema_pedidos.produto
     where id_produto = p_id_produto;

    raise notice 'Produto % removido com sucesso.', p_id_produto;
end $$;

insert into sistema_pedidos.produto (nome, valor_unitario) values ('Produto de teste', 10.00);
call sistema_pedidos.remover_produto((select max(id_produto) from sistema_pedidos.produto));
call sistema_pedidos.remover_produto(15);
call sistema_pedidos.remover_produto(9999);

--4
create or replace procedure sistema_pedidos.registrar_pedido(
    p_id_cliente int,
    inout p_id_pedido int default null
)
language plpgsql
as $$
begin
    p_id_pedido := null;

    if not exists (select 1
                     from sistema_pedidos.cliente
                    where id_cliente = p_id_cliente) then
        raise notice 'Cliente % não cadastrado. Pedido não registrado.', p_id_cliente;
        return;
    end if;

    insert into sistema_pedidos.pedido (cliente_id, data_pedido)
    values (p_id_cliente, now())
    returning id_pedido into p_id_pedido;

    raise notice 'Pedido % registrado para o cliente %.', p_id_pedido, p_id_cliente;
end $$;

call sistema_pedidos.registrar_pedido(1, null);
call sistema_pedidos.registrar_pedido(9999, null);

--5
create or replace procedure sistema_pedidos.adicionar_item_pedido(
    p_id_pedido int,
    p_id_produto int,
    p_quantidade int
)
language plpgsql
as $$
declare
    v_valor sistema_pedidos.produto.valor_unitario%type;
begin
    if p_quantidade is null or p_quantidade <= 0 then
        raise notice 'Quantidade inválida: deve ser maior que zero.';
        return;
    end if;

    if not exists (select 1
                     from sistema_pedidos.pedido
                    where id_pedido = p_id_pedido) then
        raise notice 'Pedido % não encontrado.', p_id_pedido;
        return;
    end if;

    select valor_unitario
      into v_valor
      from sistema_pedidos.produto
     where id_produto = p_id_produto;

    if not found then
        raise notice 'Produto % não encontrado.', p_id_produto;
        return;
    end if;

    if exists (select 1
                 from sistema_pedidos.detalhe_pedido
                where pedido_id = p_id_pedido
                  and produto_id = p_id_produto) then
        raise notice 'O produto % já está no pedido %.', p_id_produto, p_id_pedido;
        return;
    end if;

    insert into sistema_pedidos.detalhe_pedido (pedido_id, produto_id, quantidade, valor_unitario)
    values (p_id_pedido, p_id_produto, p_quantidade, v_valor);

    raise notice 'Item adicionado ao pedido %: produto %, qtd %, valor unitário R$ %.',
                 p_id_pedido, p_id_produto, p_quantidade, v_valor;
end $$;

call sistema_pedidos.adicionar_item_pedido(1, 1, 2);
call sistema_pedidos.adicionar_item_pedido(1, 15, 2);
call sistema_pedidos.adicionar_item_pedido(1, 1, 0);
call sistema_pedidos.adicionar_item_pedido(9999, 1, 1);
call sistema_pedidos.adicionar_item_pedido(1, 9999, 1);
