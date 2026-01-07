const functions = require("firebase-functions");
const axios = require("axios");

// Configuração da API FlightAware
const FLIGHTAWARE_API_KEY = process.env.FLIGHTAWARE_API_KEY ||
  functions.config().flightaware?.api_key ||
  "DoPXAzO86aAWofjsY3AHqSdezFvO4W24";
const FLIGHTAWARE_BASE_URL = "https://aeroapi.flightaware.com/aeroapi";

// Middleware para CORS
const cors = require("cors")({ origin: true });

// Configuração do cliente axios para FlightAware
const flightAwareClient = axios.create({
  baseURL: FLIGHTAWARE_BASE_URL,
  headers: {
    "x-apikey": FLIGHTAWARE_API_KEY,
    "Content-Type": "application/json",
  },
  timeout: 30000, // 30 segundos
});

// Função auxiliar para tratamento de erros da API
function handleFlightAwareError(error, res, defaultMessage = "Erro na API FlightAware") {
  console.error("FlightAware API Error:", {
    message: error.message,
    status: error.response?.status,
    data: error.response?.data,
    url: error.config?.url
  });

  if (error.response) {
    const status = error.response.status;
    const message = error.response.data?.error || error.response.data?.message || defaultMessage;
    
    switch (status) {
      case 401:
        return res.status(401).json({
          success: false,
          message: "Chave da API FlightAware inválida ou expirada",
          error: "UNAUTHORIZED"
        });
      case 403:
        return res.status(403).json({
          success: false,
          message: "Acesso negado pela API FlightAware",
          error: "FORBIDDEN"
        });
      case 404:
        return res.status(404).json({
          success: false,
          message: "Recurso não encontrado",
          error: "NOT_FOUND"
        });
      case 429:
        return res.status(429).json({
          success: false,
          message: "Limite de requisições excedido",
          error: "RATE_LIMIT_EXCEEDED"
        });
      default:
        return res.status(status).json({
          success: false,
          message: message,
          error: "API_ERROR"
        });
    }
  }

  return res.status(500).json({
    success: false,
    message: defaultMessage,
    error: "NETWORK_ERROR"
  });
}

// Testar conexão
exports.testConnection = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const response = await flightAwareClient.get("/airports/KJFK/flights?max_pages=1");

      res.json({
        success: true,
        message: "Conexão com FlightAware estabelecida com sucesso!",
        data: {
          airport: "JFK",
          flights_count: response.data.flights ? response.data.flights.length : 0,
          api_status: "connected",
          timestamp: new Date().toISOString()
        }
      });
    } catch (error) {
      return handleFlightAwareError(error, res, "Erro ao testar conexão com FlightAware");
    }
  });
});

// Buscar voo por número
exports.searchFlight = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const flightNumber = req.query.flight || req.body.flight;
      
      if (!flightNumber) {
        return res.status(400).json({
          success: false,
          message: "Número do voo é obrigatório",
          error: "MISSING_FLIGHT_NUMBER"
        });
      }

      // Validar formato do número do voo
      const flightRegex = /^[A-Z]{2,3}\d{1,4}[A-Z]?$/i;
      if (!flightRegex.test(flightNumber)) {
        return res.status(400).json({
          success: false,
          message: "Formato do número do voo inválido (ex: AA123, TAM3054)",
          error: "INVALID_FLIGHT_FORMAT"
        });
      }

      const response = await flightAwareClient.get(`/flights/${flightNumber.toUpperCase()}`);

      if (response.data.flights && response.data.flights.length > 0) {
        const flight = response.data.flights[0];
        
        // Enriquecer dados do voo
        const enrichedFlight = {
          ...flight,
          search_timestamp: new Date().toISOString(),
          flight_number: flightNumber.toUpperCase(),
          status_description: getFlightStatusDescription(flight.status)
        };
        
        res.json({
          success: true,
          data: enrichedFlight,
          message: `Voo ${flightNumber.toUpperCase()} encontrado`
        });
      } else {
        res.status(404).json({
          success: false,
          message: `Voo ${flightNumber.toUpperCase()} não encontrado`,
          error: "FLIGHT_NOT_FOUND"
        });
      }
      
    } catch (error) {
      return handleFlightAwareError(error, res, "Erro ao buscar informações do voo");
    }
  });
});

// Função auxiliar para descrição do status do voo
function getFlightStatusDescription(status) {
  const statusMap = {
    "Scheduled": "Programado",
    "Active": "Em voo",
    "Completed": "Concluído",
    "Cancelled": "Cancelado",
    "Diverted": "Desviado",
    "DataSource": "Fonte de dados",
    "Unknown": "Desconhecido"
  };
  
  return statusMap[status] || status;
}

// Buscar voos por aeroporto
exports.getAirportFlights = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { airport, type = "both", limit = 10 } = req.query;
      
      if (!airport) {
        return res.status(400).json({
          success: false,
          message: "Código do aeroporto é obrigatório",
          error: "MISSING_AIRPORT_CODE"
        });
      }

      // Validar código do aeroporto (IATA ou ICAO)
      const airportRegex = /^[A-Z]{3,4}$/i;
      if (!airportRegex.test(airport)) {
        return res.status(400).json({
          success: false,
          message: "Código do aeroporto inválido (ex: GRU, SBGR)",
          error: "INVALID_AIRPORT_CODE"
        });
      }

      // Validar tipo de voo
      const validTypes = ["arrivals", "departures", "both"];
      if (!validTypes.includes(type)) {
        return res.status(400).json({
          success: false,
          message: "Tipo deve ser: arrivals, departures ou both",
          error: "INVALID_FLIGHT_TYPE"
        });
      }

      // Validar limite
      const parsedLimit = parseInt(limit);
      if (isNaN(parsedLimit) || parsedLimit < 1 || parsedLimit > 100) {
        return res.status(400).json({
          success: false,
          message: "Limite deve ser um número entre 1 e 100",
          error: "INVALID_LIMIT"
        });
      }

      let endpoint;
      if (type === "arrivals") {
        endpoint = "arrivals";
      } else if (type === "departures") {
        endpoint = "departures";
      } else {
        endpoint = "flights";
      }

      const response = await flightAwareClient.get(`/airports/${airport.toUpperCase()}/${endpoint}?max_pages=1`);

      let flights = [];
      if (type === "arrivals" && response.data.arrivals) {
        flights = response.data.arrivals;
      } else if (type === "departures" && response.data.departures) {
        flights = response.data.departures;
      } else if (response.data.flights) {
        flights = response.data.flights;
      }

      // Enriquecer dados dos voos
      const enrichedFlights = flights.slice(0, parsedLimit).map(flight => ({
        ...flight,
        status_description: getFlightStatusDescription(flight.status),
        search_timestamp: new Date().toISOString()
      }));
      
      res.json({
        success: true,
        data: enrichedFlights,
        count: enrichedFlights.length,
        airport: airport.toUpperCase(),
        type: type,
        message: `${enrichedFlights.length} voos encontrados para ${airport.toUpperCase()}`
      });
      
    } catch (error) {
      return handleFlightAwareError(error, res, "Erro ao buscar voos do aeroporto");
    }
  });
});

// Buscar voos Brasil-EUA
exports.getBrazilUsaFlights = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { limit = 20, include_cargo = false } = req.query;
      
      // Validar limite
      const parsedLimit = parseInt(limit);
      if (isNaN(parsedLimit) || parsedLimit < 1 || parsedLimit > 50) {
        return res.status(400).json({
          success: false,
          message: "Limite deve ser um número entre 1 e 50",
          error: "INVALID_LIMIT"
        });
      }
      
      // Principais aeroportos brasileiros (códigos ICAO)
      const brazilianAirports = [
        { code: "SBGR", name: "São Paulo/Guarulhos" },
        { code: "SBBR", name: "Brasília" },
        { code: "SBGL", name: "Rio de Janeiro/Galeão" },
        { code: "SBRF", name: "Recife" },
        { code: "SBSV", name: "Salvador" },
        { code: "SBCT", name: "Curitiba" },
        { code: "SBPA", name: "Porto Alegre" },
        { code: "SBEG", name: "Manaus" }
      ];
      
      let allFlights = [];
      const errors = [];
      
      // Buscar voos de cada aeroporto brasileiro
      for (const airport of brazilianAirports) {
        try {
          const response = await flightAwareClient.get(`/airports/${airport.code}/departures?max_pages=1`);

          if (response.data.departures) {
            const flights = response.data.departures;
            
            // Filtrar voos Brasil-EUA (destino com código ICAO começando com K)
            const brazilUsaFlights = flights.filter(flight => {
              const originCode = flight.origin && flight.origin.code_icao;
              const destCode = flight.destination && flight.destination.code_icao;
              const aircraftType = flight.aircraft_type;
              
              // Verificar se é voo Brasil -> EUA
              const isBrazilToUsa = originCode && destCode && 
                                   originCode.startsWith("SB") && destCode.startsWith("K");
              
              // Filtrar cargueiros se não solicitado
              if (!include_cargo && aircraftType) {
                const cargoTypes = ["B74F", "B77F", "MD11F", "A30F"];
                if (cargoTypes.some(type => aircraftType.includes(type))) {
                  return false;
                }
              }
              
              return isBrazilToUsa;
            }).map(flight => ({
              ...flight,
              origin_airport_name: airport.name,
              status_description: getFlightStatusDescription(flight.status),
              route_type: "Brasil-EUA"
            }));
            
            allFlights = allFlights.concat(brazilUsaFlights);
          }
        } catch (error) {
          console.log(`Erro ao buscar voos do aeroporto ${airport.code}:`, error.message);
          errors.push({
            airport: airport.code,
            error: error.message
          });
        }
      }
      
      // Remover duplicatas baseado no identificador do voo
      const uniqueFlights = allFlights.filter((flight, index, self) => 
        index === self.findIndex(f => f.ident === flight.ident)
      );
      
      // Ordenar por horário de partida e limitar resultados
      const sortedFlights = uniqueFlights
        .sort((a, b) => {
          const timeA = new Date(a.scheduled_out || a.estimated_out || 0);
          const timeB = new Date(b.scheduled_out || b.estimated_out || 0);
          return timeA - timeB;
        })
        .slice(0, parsedLimit);
      
      res.json({
        success: true,
        data: sortedFlights,
        count: sortedFlights.length,
        total_found: uniqueFlights.length,
        airports_searched: brazilianAirports.length,
        errors: errors.length > 0 ? errors : undefined,
        search_timestamp: new Date().toISOString(),
        message: `${sortedFlights.length} voos Brasil-EUA encontrados`
      });
      
    } catch (error) {
      return handleFlightAwareError(error, res, "Erro ao buscar voos Brasil-EUA");
    }
  });
}); 

// Buscar fotos e preços de carros via Auto.dev API
exports.getCarPhotos = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { make, model, year, color } = req.query;
      
      if (!make || !model || !year) {
        return res.status(400).json({
          success: false,
          message: "Marca, modelo e ano são obrigatórios",
        });
      }

      const AUTO_DEV_API_KEY = process.env.AUTO_DEV_API_KEY || "ZrQEPSkKZWR1YXJkb2FnY2FtcG9zQGdtYWlsLmNvbQ==";
      if (!AUTO_DEV_API_KEY) {
        return res.status(500).json({
          success: false,
          message: "API Key da Auto.dev não configurada",
        });
      }

      let url = `https://auto.dev/api/listings?year_min=${year}&year_max=${year}` +
        `&make=${encodeURIComponent(make)}&model=${encodeURIComponent(model)}&limit=5`;
      
      // Mapeamento de cores em português para inglês (baseado nas cores reais da API)
      const colorMapping = {
        "Preto": "Black",
        "Branco": "White", 
        "Prata": "Silver",
        "Cinza": "Gray",
        "Azul": "Blue",
        "Vermelho": "Red",
        "Verde": "Green",
        "Amarelo": "Yellow",
        "Laranja": "Orange",
        "Rosa": "Pink",
        "Roxo": "Purple",
        "Marrom": "Brown",
        "Bege": "Beige",
        "Dourado": "Gold",
        "Champagne": "Champagne"
      };

      // Adicionar filtro de cor se especificado
      if (color && color !== "Todas") {
        const englishColor = colorMapping[color] || color;
        url += `&color=${encodeURIComponent(englishColor)}`;
      }
      
      console.log(`Buscando fotos e preços para: ${make} ${model} ${year}`);
      console.log(`URL: ${url}`);
      
      const response = await axios.get(url, {
        headers: {
          "Authorization": `Bearer ${AUTO_DEV_API_KEY}`,
          "Content-Type": "application/json",
        },
      });

      if (response.status === 200) {
        const data = response.data;
        const photos = [];
        const prices = [];
        let averagePrice = null;
        
        if (data.records && Array.isArray(data.records)) {
          console.log(`Processando ${data.records.length} registros da API`);
          
          for (const car of data.records) {
            // Coletar fotos
            if (car.photoUrls && Array.isArray(car.photoUrls)) {
              for (const photoUrl of car.photoUrls) {
                if (photoUrl && !photos.includes(photoUrl)) {
                  photos.push(photoUrl);
                }
              }
            }
            
            // Coletar preços - tentar diferentes campos possíveis
            let carPrice = null;
            
            // Tentar diferentes campos de preço
            if (car.price && typeof car.price === "number" && car.price > 0) {
              carPrice = car.price;
            } else if (car.listPrice && typeof car.listPrice === "number" && car.listPrice > 0) {
              carPrice = car.listPrice;
            } else if (car.askingPrice && typeof car.askingPrice === "number" && car.askingPrice > 0) {
              carPrice = car.askingPrice;
            } else if (car.msrp && typeof car.msrp === "number" && car.msrp > 0) {
              carPrice = car.msrp;
            } else if (car.value && typeof car.value === "number" && car.value > 0) {
              carPrice = car.value;
            }
            
            // Log para debug
            console.log(`Carro: ${car.make} ${car.model} ${car.year}`);
            console.log(`  - price: ${car.price}`);
            console.log(`  - listPrice: ${car.listPrice}`);
            console.log(`  - askingPrice: ${car.askingPrice}`);
            console.log(`  - msrp: ${car.msrp}`);
            console.log(`  - value: ${car.value}`);
            console.log(`  - Preço final: ${carPrice}`);
            
            if (carPrice) {
              prices.push(carPrice);
            }
          }
          
          // Calcular preço médio
          if (prices.length > 0) {
            const sum = prices.reduce((acc, price) => acc + price, 0);
            averagePrice = Math.round(sum / prices.length);
          }
        }
        
        console.log(`Encontradas ${photos.length} fotos e ${prices.length} preços para ${make} ${model} ${year}`);
        if (averagePrice) {
          console.log(`Preço médio: $${averagePrice.toFixed(2)}`);
        }
        
        res.json({
          success: true,
          data: photos,
          count: photos.length,
          make,
          model,
          year,
          prices: prices,
          averagePrice: averagePrice,
          priceCount: prices.length
        });
      } else {
        res.status(response.status).json({
          success: false,
          message: "Erro na API Auto.dev",
          status: response.status
        });
      }
    } catch (error) {
      console.error("Erro ao buscar fotos e preços de carro:", error.message);
      
      if (error.response) {
        res.status(error.response.status).json({
          success: false,
          message: "Erro na API Auto.dev",
          error: error.message,
          status: error.response.status
        });
      } else {
        res.status(500).json({
          success: false,
          message: "Erro interno do servidor",
          error: error.message
        });
      }
    }
  });
}); 

// Proxy de imagens da Auto.dev para contornar CORS
exports.getCarPhotoProxy = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { url } = req.query;
      if (!url) {
        return res.status(400).json({ success: false, message: "URL da imagem é obrigatória" });
      }
      const response = await require("axios").get(url, { responseType: "arraybuffer" });
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Content-Type", response.headers["content-type"] || "image/jpeg");
      res.send(Buffer.from(response.data, "binary"));
    } catch (error) {
      res.status(500).json({ success: false, message: "Erro ao buscar imagem", error: error.message });
    }
  });
});

// Buscar informações detalhadas de um voo específico
exports.getFlightDetails = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { flight_id, include_history = false } = req.query;
      
      if (!flight_id) {
        return res.status(400).json({
          success: false,
          message: "ID do voo é obrigatório",
          error: "MISSING_FLIGHT_ID"
        });
      }

      // Buscar informações básicas do voo
      const flightResponse = await flightAwareClient.get(`/flights/${flight_id}`);
      
      if (!flightResponse.data.flights || flightResponse.data.flights.length === 0) {
        return res.status(404).json({
          success: false,
          message: "Voo não encontrado",
          error: "FLIGHT_NOT_FOUND"
        });
      }

      const flight = flightResponse.data.flights[0];
      let flightDetails = {
        ...flight,
        status_description: getFlightStatusDescription(flight.status),
        search_timestamp: new Date().toISOString()
      };

      // Buscar histórico se solicitado
      if (include_history === "true") {
        try {
          const historyResponse = await flightAwareClient.get(`/flights/${flight_id}/track`);
          if (historyResponse.data.positions) {
            flightDetails.track_history = historyResponse.data.positions;
          }
        } catch (historyError) {
          console.log("Erro ao buscar histórico do voo:", historyError.message);
          flightDetails.track_history_error = "Histórico não disponível";
        }
      }

      // Buscar informações do aeroporto de origem e destino
      try {
        if (flight.origin && flight.origin.code_icao) {
          const originResponse = await flightAwareClient.get(`/airports/${flight.origin.code_icao}`);
          flightDetails.origin_details = originResponse.data;
        }
        
        if (flight.destination && flight.destination.code_icao) {
          const destResponse = await flightAwareClient.get(`/airports/${flight.destination.code_icao}`);
          flightDetails.destination_details = destResponse.data;
        }
      } catch (airportError) {
        console.log("Erro ao buscar informações dos aeroportos:", airportError.message);
      }

      res.json({
        success: true,
        data: flightDetails,
        message: `Detalhes do voo ${flight_id} obtidos com sucesso`
      });
      
    } catch (error) {
      return handleFlightAwareError(error, res, "Erro ao buscar detalhes do voo");
    }
  });
});

// Buscar voos por rota específica
exports.getRouteFlights = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const { origin, destination, limit = 10 } = req.query;
      
      if (!origin || !destination) {
        return res.status(400).json({
          success: false,
          message: "Aeroportos de origem e destino são obrigatórios",
          error: "MISSING_AIRPORTS"
        });
      }

      // Validar códigos dos aeroportos
      const airportRegex = /^[A-Z]{3,4}$/i;
      if (!airportRegex.test(origin) || !airportRegex.test(destination)) {
        return res.status(400).json({
          success: false,
          message: "Códigos dos aeroportos inválidos (ex: GRU, KJFK)",
          error: "INVALID_AIRPORT_CODES"
        });
      }

      // Validar limite
      const parsedLimit = parseInt(limit);
      if (isNaN(parsedLimit) || parsedLimit < 1 || parsedLimit > 50) {
        return res.status(400).json({
          success: false,
          message: "Limite deve ser um número entre 1 e 50",
          error: "INVALID_LIMIT"
        });
      }

      // Buscar voos da rota
      const response = await flightAwareClient.get(
        `/airports/${origin.toUpperCase()}/flights/to/${destination.toUpperCase()}?max_pages=1`
      );

      let flights = [];
      if (response.data.flights) {
        flights = response.data.flights.slice(0, parsedLimit).map(flight => ({
          ...flight,
          status_description: getFlightStatusDescription(flight.status),
          route: `${origin.toUpperCase()} → ${destination.toUpperCase()}`,
          search_timestamp: new Date().toISOString()
        }));
      }

      res.json({
        success: true,
        data: flights,
        count: flights.length,
        route: {
          origin: origin.toUpperCase(),
          destination: destination.toUpperCase()
        },
        message: `${flights.length} voos encontrados na rota ${origin.toUpperCase()} → ${destination.toUpperCase()}`
      });
      
    } catch (error) {
      return handleFlightAwareError(error, res, "Erro ao buscar voos da rota");
    }
  });
});