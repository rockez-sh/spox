use Mix.Config

config :cors_plug,
  origin: ["http://localhost:3000"],
  max_age: 1,
  methods: ["GET", "POST"]
