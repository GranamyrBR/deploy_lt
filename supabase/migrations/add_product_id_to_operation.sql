-- Script para adicionar suporte a operações de produtos na tabela operation
-- Este script adiciona o campo product_id à tabela operation para suportar operações de produtos

-- Adicionar colunas para suporte a operações de produtos
ALTER TABLE public.operation 
ADD COLUMN product_id integer,
ADD COLUMN product_value_usd numeric,
ADD COLUMN quantity integer;

-- Adicionar foreign key constraint para product_id
ALTER TABLE public.operation 
ADD CONSTRAINT operation_product_id_fkey 
FOREIGN KEY (product_id) REFERENCES public.product(product_id);

-- Modificar a constraint para permitir que service_id seja NULL quando product_id estiver presente
ALTER TABLE public.operation 
DROP CONSTRAINT operation_service_id_fkey;

ALTER TABLE public.operation 
ALTER COLUMN service_id DROP NOT NULL;

ALTER TABLE public.operation 
ADD CONSTRAINT operation_service_id_fkey 
FOREIGN KEY (service_id) REFERENCES public.service(id);

-- Adicionar constraint para garantir que pelo menos service_id OU product_id esteja presente
ALTER TABLE public.operation 
ADD CONSTRAINT operation_service_or_product_check 
CHECK (
  (service_id IS NOT NULL AND product_id IS NULL) OR 
  (service_id IS NULL AND product_id IS NOT NULL)
);

-- Adicionar comentários para documentar as mudanças
COMMENT ON COLUMN public.operation.product_id IS 'ID do produto para operações de produtos. Mutuamente exclusivo com service_id.';
COMMENT ON COLUMN public.operation.product_value_usd IS 'Valor do produto em USD para operações de produtos.';
COMMENT ON COLUMN public.operation.quantity IS 'Quantidade do produto para operações de produtos.';
COMMENT ON CONSTRAINT operation_service_or_product_check ON public.operation IS 'Garante que uma operação tenha ou service_id ou product_id, mas não ambos.';

-- Adicionar índice para melhorar performance de consultas por product_id
CREATE INDEX idx_operation_product_id ON public.operation(product_id) WHERE product_id IS NOT NULL;

-- Script executado com sucesso. A tabela operation agora suporta operações de produtos.