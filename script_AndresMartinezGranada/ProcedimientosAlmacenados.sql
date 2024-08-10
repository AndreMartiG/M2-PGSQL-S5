--1. Crea una nueva cuenta bancaria para un cliente, asignando un número de cuenta único y estableciendo un saldo inicial.
CREATE OR REPLACE FUNCTION crear_cuenta(
    v_clienteId INT, v_numeroCuenta VARCHAR, v_tipoCuenta VARCHAR, v_saldo NUMERIC, v_estado VARCHAR, v_sucursalId INT
  ) RETURNS VOID 
  AS $$
    BEGIN
      INSERT INTO cuentas_bancarias (cliente_id, numero_cuenta, tipo_cuenta, saldo, estado, sucursal_id)
	    VALUES (v_clienteId, v_numeroCuenta, v_tipoCuenta, v_saldo, v_estado, v_sucursalId);
    END;
  $$ LANGUAGE plpgsql;

SELECT crear_cuenta(1, '4333222111', 'ahorro', 5000, 'activa', 1);

--2. Actualiza la información personal de un cliente, como dirección, teléfono y correo electrónico, basado en el ID del cliente.
CREATE OR REPLACE FUNCTION actualizar_cliente(
    v_clienteId INT, v_direccion VARCHAR, v_telefono VARCHAR, v_correoElectronico VARCHAR
  ) RETURNS VOID 
  AS $$
    BEGIN
      UPDATE clientes
        SET direccion = v_direccion, telefono = v_telefono, correo_electronico = v_correoElectronico
        WHERE cliente_id = v_clienteId;
    END;
  $$ LANGUAGE plpgsql;

SELECT actualizar_cliente(2, '123th Washington Avenue', '555-1234', 'maria.camila.z@mail.com');

--3. Elimina una cuenta bancaria específica del sistema, incluyendo la eliminación de todas las transacciones asociadas.
CREATE OR REPLACE FUNCTION eliminar_cuenta_y_transacciones(
    v_cuentaId INT
  ) RETURNS VOID 
  AS $$
    BEGIN    
      DELETE FROM cuentas_bancarias WHERE cuenta_id = v_cuentaId;
	  DELETE FROM transacciones WHERE cuenta_id = v_cuentaId;
	  DELETE FROM tarjetas_credito WHERE cuenta_id = v_cuentaId;
	  DELETE FROM prestamos WHERE cuenta_id = v_cuentaId;
    END;
  $$ LANGUAGE plpgsql;

SELECT eliminar_cuenta_y_transacciones(2);

--4. Realiza una transferencia de fondos desde una cuenta a otra, asegurando que ambas cuentas se actualicen correctamente y se registre la transacción.
CREATE OR REPLACE FUNCTION transferencia(
    v_cuentaIdOrigen INT, v_cuentaIdDestino INT, v_monto NUMERIC
  ) RETURNS VOID 
  AS $$
    BEGIN
      IF (SELECT saldo FROM cuentas_bancarias WHERE cuenta_id = v_cuentaIdOrigen) < v_monto THEN
	    RAISE EXCEPTION 'Fondos insuficientes para realizar la transferencia';
      END IF;
      UPDATE cuentas_bancarias
	    SET saldo = saldo - v_monto
	    WHERE cuenta_id = v_cuentaIdOrigen;
	  UPDATE cuentas_bancarias
	    SET saldo = saldo + v_monto
		WHERE cuenta_id = v_cuentaIdDestino;
	  INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, descripcion)
		VALUES (v_cuentaIdOrigen, 'transferencia', v_monto, 'Transferencia a cuenta');
	  INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, descripcion)
		VALUES (v_cuentaIdDestino, 'deposito', v_monto, 'Transferencia recibida');
    END;
  $$ LANGUAGE plpgsql;

select transferencia(1, 5, 2000);

--5. Registra una nueva transacción (depósito, retiro) en el sistema, actualizando el saldo de la cuenta asociada.
CREATE OR REPLACE FUNCTION crear_transaccion(
    v_cuentaId INT, v_tipoTransaccion VARCHAR, v_monto NUMERIC, v_descripcion VARCHAR
  ) RETURNS VOID 
  AS $$
    BEGIN
      IF v_tipoTransaccion = 'deposito' THEN
        UPDATE cuentas_bancarias
          SET saldo = saldo + v_monto
          WHERE cuenta_id = v_cuentaId;
      ELSIF v_tipoTransaccion = 'retiro' THEN
        UPDATE cuentas_bancarias
          SET saldo = saldo - v_monto
          WHERE cuenta_id = v_cuentaId;
      ELSE
        RAISE EXCEPTION 'Tipo de transacción no permitida';
      END IF;
      INSERT INTO transacciones (cuenta_id, tipo_transaccion, monto, descripcion)
        VALUES (v_cuentaId, v_tipoTransaccion, v_monto, v_descripcion);
    END;
  $$ LANGUAGE plpgsql;

SELECT crear_transaccion(2, 'deposito', 15000, 'Deposito en efectivo');

--6. Calcula el saldo total combinado de todas las cuentas bancarias pertenecientes a un cliente específico.
CREATE OR REPLACE FUNCTION saldo_cliente(
    v_clienteId INT
  ) RETURNS NUMERIC 
  AS $$
    DECLARE saldo_total NUMERIC DEFAULT 0;
    BEGIN
      SELECT SUM(saldo)
        INTO saldo_total
        FROM cuentas_bancarias
        WHERE cliente_id = v_clienteId;
      RETURN saldo_total;
    END;
  $$ LANGUAGE plpgsql;

SELECT saldo_cliente(2);

--7. Genera un reporte detallado de todas las transacciones realizadas en un rango de fechas específico.
CREATE OR REPLACE FUNCTION reporte_transacciones(
    v_fechaInicio TIMESTAMP, v_fechaFin TIMESTAMP
  ) RETURNS TABLE (
    transaccion_id INT, cuenta_id INT, tipo_transaccion VARCHAR, monto NUMERIC, fecha_transaccion timestamp, descripcion VARCHAR
  ) AS $$
    BEGIN
      RETURN QUERY
        SELECT TR.transaccion_id, TR.cuenta_id, TR.tipo_transaccion, TR.monto, TR.fecha_transaccion, TR.descripcion
          FROM transacciones TR 
          WHERE TR.fecha_transaccion BETWEEN v_fechaInicio AND v_fechaFin;
    END;
  $$ LANGUAGE plpgsql;

select * from reporte_transacciones('2024-05-01', '2024-06-30');