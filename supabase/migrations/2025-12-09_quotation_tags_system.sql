-- ============================================================================
-- Sistema de Tags para Cotações
-- Data: 2025-12-09
-- Descrição: Sistema completo de tags customizáveis para cotações
-- ============================================================================

-- ============================================================================
-- 1. TABELA DE TAGS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.quotation_tag (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    color VARCHAR(7) NOT NULL DEFAULT '#3B82F6', -- Hex color (ex: #FF5733)
    description TEXT,
    icon VARCHAR(50), -- Nome do ícone (ex: 'star', 'vip', 'urgent')
    
    -- Ordem de exibição
    display_order INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_system BOOLEAN DEFAULT false, -- Tags do sistema não podem ser deletadas
    
    -- Auditoria
    created_by TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT tag_name_length CHECK (LENGTH(name) >= 2 AND LENGTH(name) <= 50),
    CONSTRAINT tag_color_format CHECK (color ~* '^#[0-9A-F]{6}$')
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_quotation_tag_name ON public.quotation_tag(name);
CREATE INDEX IF NOT EXISTS idx_quotation_tag_active ON public.quotation_tag(is_active);
CREATE INDEX IF NOT EXISTS idx_quotation_tag_order ON public.quotation_tag(display_order);

-- Comentários
COMMENT ON TABLE public.quotation_tag IS 'Tags customizáveis para categorizar cotações';
COMMENT ON COLUMN public.quotation_tag.is_system IS 'Tags do sistema (VIP, Urgente, etc) não podem ser deletadas';

-- ============================================================================
-- 2. TABELA DE RELACIONAMENTO (Many-to-Many)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.quotation_tag_assignment (
    id BIGSERIAL PRIMARY KEY,
    quotation_id BIGINT NOT NULL REFERENCES public.quotation(id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES public.quotation_tag(id) ON DELETE CASCADE,
    
    -- Auditoria
    assigned_by TEXT NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Uma cotação não pode ter a mesma tag duplicada
    CONSTRAINT unique_quotation_tag UNIQUE (quotation_id, tag_id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_tag_assignment_quotation ON public.quotation_tag_assignment(quotation_id);
CREATE INDEX IF NOT EXISTS idx_tag_assignment_tag ON public.quotation_tag_assignment(tag_id);

-- Comentários
COMMENT ON TABLE public.quotation_tag_assignment IS 'Relacionamento entre cotações e tags (many-to-many)';

-- ============================================================================
-- 3. TRIGGER PARA ATUALIZAR updated_at
-- ============================================================================
CREATE OR REPLACE FUNCTION update_quotation_tag_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_quotation_tag_timestamp ON public.quotation_tag;

CREATE TRIGGER trigger_update_quotation_tag_timestamp
    BEFORE UPDATE ON public.quotation_tag
    FOR EACH ROW
    EXECUTE FUNCTION update_quotation_tag_timestamp();

-- ============================================================================
-- 4. FUNÇÃO: CRIAR TAG
-- ============================================================================
CREATE OR REPLACE FUNCTION create_quotation_tag(
    p_name VARCHAR,
    p_color VARCHAR DEFAULT '#3B82F6',
    p_description TEXT DEFAULT NULL,
    p_icon VARCHAR DEFAULT NULL,
    p_created_by TEXT DEFAULT 'system'
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    color VARCHAR,
    description TEXT,
    icon VARCHAR,
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tag_id BIGINT;
BEGIN
    -- Validar nome
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) < 2 THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::TEXT, NULL::VARCHAR, false, 'Nome da tag deve ter pelo menos 2 caracteres'::TEXT;
        RETURN;
    END IF;
    
    -- Verificar se já existe
    IF EXISTS (SELECT 1 FROM public.quotation_tag WHERE LOWER(name) = LOWER(TRIM(p_name))) THEN
        RETURN QUERY SELECT NULL::BIGINT, NULL::VARCHAR, NULL::VARCHAR, NULL::TEXT, NULL::VARCHAR, false, 'Tag com este nome já existe'::TEXT;
        RETURN;
    END IF;
    
    -- Inserir tag
    INSERT INTO public.quotation_tag (name, color, description, icon, created_by)
    VALUES (TRIM(p_name), p_color, p_description, p_icon, p_created_by)
    RETURNING quotation_tag.id INTO v_tag_id;
    
    -- Retornar sucesso
    RETURN QUERY 
    SELECT 
        t.id,
        t.name,
        t.color,
        t.description,
        t.icon,
        true,
        'Tag criada com sucesso'::TEXT
    FROM public.quotation_tag t
    WHERE t.id = v_tag_id;
END;
$$;

-- ============================================================================
-- 5. FUNÇÃO: LISTAR TAGS
-- ============================================================================
CREATE OR REPLACE FUNCTION get_quotation_tags(
    p_active_only BOOLEAN DEFAULT true
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    color VARCHAR,
    description TEXT,
    icon VARCHAR,
    display_order INTEGER,
    is_active BOOLEAN,
    is_system BOOLEAN,
    usage_count BIGINT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.name,
        t.color,
        t.description,
        t.icon,
        t.display_order,
        t.is_active,
        t.is_system,
        COUNT(ta.id) as usage_count,
        t.created_at
    FROM public.quotation_tag t
    LEFT JOIN public.quotation_tag_assignment ta ON ta.tag_id = t.id
    WHERE (NOT p_active_only OR t.is_active = true)
    GROUP BY t.id
    ORDER BY t.display_order, t.name;
END;
$$;

-- ============================================================================
-- 6. FUNÇÃO: ATRIBUIR TAG À COTAÇÃO
-- ============================================================================
CREATE OR REPLACE FUNCTION assign_tag_to_quotation(
    p_quotation_id BIGINT,
    p_tag_id BIGINT,
    p_assigned_by TEXT DEFAULT 'system'
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se cotação existe
    IF NOT EXISTS (SELECT 1 FROM public.quotation WHERE id = p_quotation_id) THEN
        RETURN QUERY SELECT false, 'Cotação não encontrada'::TEXT;
        RETURN;
    END IF;
    
    -- Verificar se tag existe e está ativa
    IF NOT EXISTS (SELECT 1 FROM public.quotation_tag WHERE id = p_tag_id AND is_active = true) THEN
        RETURN QUERY SELECT false, 'Tag não encontrada ou inativa'::TEXT;
        RETURN;
    END IF;
    
    -- Inserir (ON CONFLICT ignora se já existe)
    INSERT INTO public.quotation_tag_assignment (quotation_id, tag_id, assigned_by)
    VALUES (p_quotation_id, p_tag_id, p_assigned_by)
    ON CONFLICT (quotation_id, tag_id) DO NOTHING;
    
    RETURN QUERY SELECT true, 'Tag atribuída com sucesso'::TEXT;
END;
$$;

-- ============================================================================
-- 7. FUNÇÃO: REMOVER TAG DA COTAÇÃO
-- ============================================================================
CREATE OR REPLACE FUNCTION remove_tag_from_quotation(
    p_quotation_id BIGINT,
    p_tag_id BIGINT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.quotation_tag_assignment
    WHERE quotation_id = p_quotation_id AND tag_id = p_tag_id;
    
    IF FOUND THEN
        RETURN QUERY SELECT true, 'Tag removida com sucesso'::TEXT;
    ELSE
        RETURN QUERY SELECT false, 'Tag não estava atribuída à cotação'::TEXT;
    END IF;
END;
$$;

-- ============================================================================
-- 8. FUNÇÃO: BUSCAR TAGS DE UMA COTAÇÃO
-- ============================================================================
CREATE OR REPLACE FUNCTION get_quotation_tags_by_quotation_id(
    p_quotation_id BIGINT
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    color VARCHAR,
    description TEXT,
    icon VARCHAR,
    assigned_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.name,
        t.color,
        t.description,
        t.icon,
        ta.assigned_at
    FROM public.quotation_tag t
    INNER JOIN public.quotation_tag_assignment ta ON ta.tag_id = t.id
    WHERE ta.quotation_id = p_quotation_id
    ORDER BY t.display_order, t.name;
END;
$$;

-- ============================================================================
-- 9. FUNÇÃO: ATUALIZAR TAG
-- ============================================================================
CREATE OR REPLACE FUNCTION update_quotation_tag(
    p_tag_id BIGINT,
    p_name VARCHAR DEFAULT NULL,
    p_color VARCHAR DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_icon VARCHAR DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verificar se tag existe
    IF NOT EXISTS (SELECT 1 FROM public.quotation_tag WHERE id = p_tag_id) THEN
        RETURN QUERY SELECT false, 'Tag não encontrada'::TEXT;
        RETURN;
    END IF;
    
    -- Atualizar apenas campos fornecidos
    UPDATE public.quotation_tag
    SET 
        name = COALESCE(p_name, name),
        color = COALESCE(p_color, color),
        description = COALESCE(p_description, description),
        icon = COALESCE(p_icon, icon),
        is_active = COALESCE(p_is_active, is_active)
    WHERE id = p_tag_id;
    
    RETURN QUERY SELECT true, 'Tag atualizada com sucesso'::TEXT;
END;
$$;

-- ============================================================================
-- 10. FUNÇÃO: DELETAR TAG
-- ============================================================================
CREATE OR REPLACE FUNCTION delete_quotation_tag(
    p_tag_id BIGINT
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_system BOOLEAN;
BEGIN
    -- Verificar se é tag do sistema
    SELECT is_system INTO v_is_system
    FROM public.quotation_tag
    WHERE id = p_tag_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Tag não encontrada'::TEXT;
        RETURN;
    END IF;
    
    IF v_is_system THEN
        RETURN QUERY SELECT false, 'Tags do sistema não podem ser deletadas'::TEXT;
        RETURN;
    END IF;
    
    -- Deletar (CASCADE remove assignments)
    DELETE FROM public.quotation_tag WHERE id = p_tag_id;
    
    RETURN QUERY SELECT true, 'Tag deletada com sucesso'::TEXT;
END;
$$;

-- ============================================================================
-- 11. INSERIR TAGS PADRÃO DO SISTEMA
-- ============================================================================
INSERT INTO public.quotation_tag (name, color, description, icon, is_system, display_order, created_by)
VALUES 
    ('VIP', '#FFD700', 'Cliente VIP - Prioridade máxima', 'star', true, 1, 'system'),
    ('Urgente', '#EF4444', 'Cotação urgente - Requer atenção imediata', 'priority_high', true, 2, 'system'),
    ('Grupo Grande', '#8B5CF6', 'Grupo com mais de 20 pessoas', 'groups', true, 3, 'system'),
    ('Internacional', '#3B82F6', 'Cliente internacional', 'public', true, 4, 'system'),
    ('Corporativo', '#10B981', 'Empresa/corporativo', 'business', true, 5, 'system'),
    ('Evento Especial', '#F59E0B', 'Evento especial (casamento, aniversário)', 'celebration', true, 6, 'system'),
    ('Repetição', '#6366F1', 'Cliente que já fez outras cotações', 'repeat', true, 7, 'system'),
    ('Desconto', '#EC4899', 'Cotação com desconto especial', 'discount', true, 8, 'system')
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- 12. VIEWS ÚTEIS
-- ============================================================================

-- View: Cotações com suas tags
CREATE OR REPLACE VIEW quotation_with_tags AS
SELECT 
    q.id,
    q.quotation_number,
    q.client_name,
    q.status,
    q.total,
    q.currency,
    COALESCE(
        json_agg(
            json_build_object(
                'id', t.id,
                'name', t.name,
                'color', t.color,
                'icon', t.icon
            ) ORDER BY t.display_order, t.name
        ) FILTER (WHERE t.id IS NOT NULL),
        '[]'::json
    ) as tags
FROM public.quotation q
LEFT JOIN public.quotation_tag_assignment ta ON ta.quotation_id = q.id
LEFT JOIN public.quotation_tag t ON t.id = ta.tag_id AND t.is_active = true
GROUP BY q.id;

-- View: Estatísticas de tags
CREATE OR REPLACE VIEW quotation_tag_stats AS
SELECT 
    t.id,
    t.name,
    t.color,
    t.icon,
    COUNT(ta.id) as usage_count,
    COUNT(DISTINCT ta.quotation_id) as quotation_count
FROM public.quotation_tag t
LEFT JOIN public.quotation_tag_assignment ta ON ta.tag_id = t.id
GROUP BY t.id
ORDER BY usage_count DESC;

-- ============================================================================
-- COMENTÁRIOS FINAIS
-- ============================================================================
COMMENT ON FUNCTION create_quotation_tag IS 'Cria uma nova tag customizada';
COMMENT ON FUNCTION get_quotation_tags IS 'Lista todas as tags com contagem de uso';
COMMENT ON FUNCTION assign_tag_to_quotation IS 'Atribui uma tag a uma cotação';
COMMENT ON FUNCTION remove_tag_from_quotation IS 'Remove uma tag de uma cotação';
COMMENT ON FUNCTION get_quotation_tags_by_quotation_id IS 'Busca todas as tags de uma cotação específica';
COMMENT ON FUNCTION update_quotation_tag IS 'Atualiza dados de uma tag';
COMMENT ON FUNCTION delete_quotation_tag IS 'Deleta uma tag (exceto tags do sistema)';

-- ============================================================================
-- VERIFICAÇÃO
-- ============================================================================
SELECT 'Sistema de Tags instalado com sucesso!' as status;
SELECT COUNT(*) as total_tags_sistema FROM public.quotation_tag WHERE is_system = true;
