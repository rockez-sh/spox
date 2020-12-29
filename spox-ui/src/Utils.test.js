import { apiCall } from "./Utils";
beforeAll(() => jest.spyOn(window, "fetch"));

test("apiCall 200", (done) => {
  window.fetch.mockResolvedValueOnce({
    ok: true,
    status: 200,
    json: async () => ({ success: true }),
  });

  let cb200 = jest.fn((x) => x);
  let cbFail = jest.fn((x) => console.log(x));

  apiCall(
    "/api/sch",
    { method: "POST", body: `{"name":"sample"}` },
    { 200: cb200 },
    cbFail
  ).then(() => {
    expect(window.fetch).toHaveBeenCalledWith(
      expect.stringMatching(/\/api\/sch$/),
      expect.objectContaining({
        method: "POST",
        body: `{"name":"sample"}`,
      })
    );
    expect(cb200).toHaveBeenCalledWith({ success: true });
    done();
  });
});

test("apiCall error", (done) => {
  window.fetch.mockRejectedValueOnce(new Error("Async error"));
  let cbFail = jest.fn();
  apiCall(
    "/api/sch",
    { method: "POST", body: `{"name":"sample"}` },
    {},
    cbFail
  ).then(() => {
    expect(window.fetch).toHaveBeenCalledWith(
      expect.stringMatching(/\/api\/sch$/),
      expect.objectContaining({
        method: "POST",
        body: `{"name":"sample"}`,
      })
    );
    expect(cbFail).toHaveBeenCalledWith(new Error("Async error"), true);
    done();
  });
});

test("apiCall callback not registered", (done) => {
  let resp = {
    ok: true,
    status: 201,
    json: async () => ({ success: true }),
  };
  window.fetch.mockResolvedValueOnce(resp);

  let cbFail = jest.fn();

  apiCall(
    "/api/sch",
    { method: "POST", body: `{"name":"sample"}` },
    {},
    cbFail
  ).then(() => {
    expect(window.fetch).toHaveBeenCalledWith(
      expect.stringMatching(/\/api\/sch$/),
      expect.objectContaining({
        method: "POST",
        body: `{"name":"sample"}`,
      })
    );
    expect(cbFail).toHaveBeenCalledWith(resp);
    done();
  });
});

test("apiCall callback with function", (done) => {
  let resp = {
    ok: true,
    status: 201,
    json: async () => ({ success: true }),
  };
  window.fetch.mockResolvedValueOnce(resp);
  let cb = jest.fn();

  apiCall("/api/sch", { method: "POST", body: `{"name":"sample"}` }, cb).then(
    () => {
      expect(window.fetch).toHaveBeenCalledWith(
        expect.stringMatching(/\/api\/sch$/),
        expect.objectContaining({
          method: "POST",
          body: `{"name":"sample"}`,
        })
      );
      expect(cb).toHaveBeenCalledWith(201, { success: true });
      done();
    }
  );
});

test("apiCall return promise when no callback", (done) => {
  let resp = {
    ok: true,
    status: 201,
    json: async () => ({ success: true }),
  };
  window.fetch.mockResolvedValueOnce(resp);

  let cb = jest.fn(({ status, json }) => {
    expect(status).toEqual(201);
    expect(json).toEqual({ success: true });
    done();
  });

  apiCall("/api/sch", { method: "POST", body: `{"name":"sample"}` }).then(cb);
});
