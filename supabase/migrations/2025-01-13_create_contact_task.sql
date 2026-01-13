-- =====================================================
-- Migration: Create contact_task table for B2C follow-ups
-- Date: 2025-01-13
-- Description: Tabela para gerenciar tarefas e follow-ups de contatos B2C
--              Espelha a estrutura de account_task mas para a tabela contact
-- =====================================================

-- Criar tabela contact_task
CREATE TABLE IF NOT EXISTS public.contact_task (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  contact_id integer NOT NULL,
  assigned_to_user_id uuid,
  task_type character varying NOT NULL CHECK (task_type::text = ANY (ARRAY[
    'follow_up'::character varying::text,
    'call'::character varying::text,
    'email'::character varying::text,
    'whatsapp'::character varying::text,
    'meeting'::character varying::text,
    'visit'::character varying::text,
    'other'::character varying::text
  ])),
  title character varying NOT NULL,
  description text,
  due_date timestamp with time zone,
  completed_at timestamp with time zone,
  completion_notes text,
  priority character varying DEFAULT 'normal'::character varying CHECK (priority::text = ANY (ARRAY[
    'low'::character varying::text,
    'normal'::character varying::text,
    'high'::character varying::text,
    'urgent'::character varying::text
  ])),
  status character varying DEFAULT 'pending'::character varying CHECK (status::text = ANY (ARRAY[
    'pending'::character varying::text,
    'in_progress'::character varying::text,
    'completed'::character varying::text,
    'cancelled'::character varying::text
  ])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  created_by uuid,
  
  CONSTRAINT contact_task_pkey PRIMARY KEY (id),
  CONSTRAINT contact_task_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contact(id) ON DELETE CASCADE,
  CONSTRAINT contact_task_assigned_to_user_id_fkey FOREIGN KEY (assigned_to_user_id) REFERENCES public."user"(id),
  CONSTRAINT contact_task_created_by_fkey FOREIGN KEY (created_by) REFERENCES public."user"(id)
);

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_contact_task_contact_id ON public.contact_task(contact_id);
CREATE INDEX IF NOT EXISTS idx_contact_task_assigned_to ON public.contact_task(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_contact_task_due_date ON public.contact_task(due_date);
CREATE INDEX IF NOT EXISTS idx_contact_task_status ON public.contact_task(status);
CREATE INDEX IF NOT EXISTS idx_contact_task_priority ON public.contact_task(priority);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_contact_task_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_contact_task_updated_at
  BEFORE UPDATE ON public.contact_task
  FOR EACH ROW
  EXECUTE FUNCTION update_contact_task_updated_at();

-- Comentários
COMMENT ON TABLE public.contact_task IS 'Tarefas e follow-ups para contatos B2C';
COMMENT ON COLUMN public.contact_task.task_type IS 'Tipo de tarefa: follow_up, call, email, whatsapp, meeting, visit, other';
COMMENT ON COLUMN public.contact_task.priority IS 'Prioridade: low, normal, high, urgent';
COMMENT ON COLUMN public.contact_task.status IS 'Status: pending, in_progress, completed, cancelled';
